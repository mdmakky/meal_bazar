import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';
import '../../ai/presentation/ai_entry.dart';
import '../../export/presentation/export_actions.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
import '../../money/presentation/money_sheets.dart';
import '../../today/application/day_grid.dart';
import '../application/meal_providers.dart';
import '../domain/meal.dart';
import 'meal_grid.dart';
import 'meal_widgets.dart';

/// মিল: the daily entry screen. Mess and manager, a month pill and a day
/// switcher, the member × meal stepper grid with column totals, the day's
/// total; then the month's per-member meals (SQL).
class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key});

  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
  DateTime _day = today();

  void _shift(int days) =>
      setState(() => _day = dayOnly(_day.add(Duration(days: days, hours: 2))));

  /// Previous/next calendar month: its first day, or today in this month.
  void _shiftMonth(int delta) {
    final now = today();
    final first = DateTime(_day.year, _day.month + delta);
    setState(
      () => _day = first.year == now.year && first.month == now.month
          ? now
          : first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null) return const Scaffold(body: LoadingView());

    final key = (messId: messId, day: _day);
    final manager = ref.watch(amIManagerProvider);
    final mess = ref.watch(currentMessProvider);
    final myId = plainMemberId(ref);
    final ownOff = ownOffId(ref, _day);
    final membersAsync = ref.watch(membersProvider(messId));
    final typesAsync = ref.watch(mealTypesProvider(messId));
    final gridAsync = ref.watch(dayGridProvider(key));

    void retry() {
      ref.invalidate(membersProvider(messId));
      ref.invalidate(mealTypesProvider(messId));
      ref.invalidate(dayEntriesProvider(key));
      monthProviders(messId).forEach(ref.invalidate);
    }

    final error = [
      if (!membersAsync.hasValue) membersAsync.error,
      if (!typesAsync.hasValue) typesAsync.error,
      if (!gridAsync.hasValue) gridAsync.error,
    ].nonNulls.firstOrNull;

    final List<Widget> grid;
    var rows = const <Member>[];
    var types = const <MealType>[];
    if (error != null) {
      grid = [ErrorView(message: failureText(context, error), onRetry: retry)];
    } else if (!membersAsync.hasValue ||
        !typesAsync.hasValue ||
        !gridAsync.hasValue) {
      grid = [const LoadingView(rows: 5)];
    } else {
      final members = membersAsync.value!;
      (:rows, :types) = gridShape(
        members,
        typesAsync.value!,
        gridAsync.value!.values,
        _day,
      );
      final hasMembers = members.any((m) => m.status != MemberStatus.pending);
      grid = [
        if (!hasMembers)
          EmptyView(
            icon: Icons.group_outlined,
            message: l.todayNoMembers,
            actionLabel: manager ? l.membersAdd : null,
            onAction: () => context.push('/more/members'),
          )
        else if (rows.isEmpty)
          // The mess has members, just none present on this day.
          EmptyView(
            icon: Icons.event_busy_outlined,
            message: l.dashNobodyThatDay,
            actionLabel: _day == today() ? null : l.todayBackToToday,
            onAction: () => setState(() => _day = today()),
          )
        else if (types.isEmpty)
          EmptyView(
            icon: Icons.restaurant_outlined,
            message: l.todayNoMealTypes,
            actionLabel: manager ? l.todayNoMealTypesAction : null,
            onAction: () => context.push('/more/meal-types'),
          )
        else ...[
          if (manager)
            _BulkActions(
              dayKey: key,
              members: [
                for (final m in rows)
                  if (presentOn(m, _day)) m,
              ],
              types: [
                for (final t in types)
                  if (t.enabled) t,
              ],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: MealStepperGrid(
                dayKey: key,
                rows: rows,
                types: types,
                editable: manager,
                ownOffId: ownOff,
              ),
            ),
          ),
          _DayTotal(dayKey: key, types: types),
          if (manager)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.md,
                AppSpace.gutter,
                0,
              ),
              child: Text(
                l.mealGridHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (myId != null && mess != null)
            MealOffHint(cutoff: mess.mealOffCutoff),
        ],
      ];
    }

    return Scaffold(
      floatingActionButton: manager && rows.isNotEmpty && types.isNotEmpty
          ? FloatingActionButton(
              tooltip: l.mealGridAdd,
              onPressed: () => _add(key, rows, types),
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            retry();
            await ref
                .read(dayEntriesProvider(key).future)
                .catchError((_) => const <MealEntry>[]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpace.xxxl * 2),
            children: [
              _Header(messId: messId, day: _day, onShiftMonth: _shiftMonth),
              _DaySwitcher(
                day: _day,
                onShift: _shift,
                onToday: () => setState(() => _day = today()),
              ),
              SyncLine(messId: messId),
              const SizedBox(height: AppSpace.md),
              ...grid,
              if (mess != null)
                _MonthSummary(
                  messId: messId,
                  start: periodStartFor(_day, mess.monthStartDay),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// FAB chooser: AI, bazar, expense, deposit, guest.
  Future<void> _add(
    MessDay key,
    List<Member> rows,
    List<MealType> types,
  ) async {
    final l = AppLocalizations.of(context);
    final action = await pickOne<VoidCallback>(
      context,
      title: l.mealGridAddTitle,
      options: [
        (() => showMealDraftSheet(context, day: _day), l.mealGridAi),
        (() => showAddBazarSheet(context), l.todayActionBazar),
        (() => showAddExpenseSheet(context), l.todayActionExpense),
        (() => showAddDepositSheet(context), l.todayActionDeposit),
        (() => addGuest(context, ref, key, rows, types), l.todayActionGuest),
      ],
    );
    if (mounted) action?.call();
  }
}

/// Mess name, its manager, and the month pill.
class _Header extends ConsumerWidget {
  const _Header({
    required this.messId,
    required this.day,
    required this.onShiftMonth,
  });

  final String messId;
  final DateTime day;
  final ValueChanged<int> onShiftMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final mess = ref.watch(currentMessProvider);
    final manager = (ref.watch(membersProvider(messId)).value ?? const [])
        .where((m) => m.isActiveManager)
        .firstOrNull;
    final long = Fmt.dateLong(
      day,
      locale: Localizations.localeOf(context).languageCode,
      banglaDigits: bnDigits(context),
    );
    final month = long.substring(long.indexOf(' ') + 1);
    final now = today();
    final isThisMonth = day.year == now.year && day.month == now.month;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.sm,
        0,
      ),
      child: Row(
        spacing: AppSpace.sm,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mess?.name ?? l.mealsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall,
                ),
                if (manager != null)
                  Text(
                    l.mealGridManager(manager.displayName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: p.inkSecondary),
                  ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(AppSize.touch),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l.mealGridPrevMonth,
                  onPressed: () => onShiftMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(month, style: text.labelMedium),
                IconButton(
                  tooltip: l.mealGridNextMonth,
                  onPressed: isThisMonth ? null : () => onShiftMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ‹  date (আজ)  ›; tomorrow at most, for planning ahead.
class _DaySwitcher extends StatelessWidget {
  const _DaySwitcher({
    required this.day,
    required this.onShift,
    required this.onToday,
  });

  final DateTime day;
  final ValueChanged<int> onShift;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final now = today();
    final isToday = day == now;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          IconButton.outlined(
            tooltip: l.todayPrevDay,
            onPressed: () => onShift(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: isToday ? null : onToday,
              child: Column(
                children: [
                  Text(
                    Fmt.dateLong(
                      day,
                      locale: Localizations.localeOf(context).languageCode,
                      banglaDigits: bnDigits(context),
                    ),
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                  Text(
                    isToday ? l.todayIsToday : l.todayBackToToday,
                    style: text.labelSmall?.copyWith(
                      color: isToday ? p.accent : p.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton.outlined(
            tooltip: l.todayNextDay,
            onPressed: day.isBefore(now) || isToday ? () => onShift(1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// "সবাই ১" and "গতকালের মতো", each one batched write, and the cook share
/// (managers).
class _BulkActions extends ConsumerStatefulWidget {
  const _BulkActions({
    required this.dayKey,
    required this.members,
    required this.types,
  });

  final MessDay dayKey;

  /// Present members and enabled types only.
  final List<Member> members;
  final List<MealType> types;

  @override
  ConsumerState<_BulkActions> createState() => _BulkActionsState();
}

class _BulkActionsState extends ConsumerState<_BulkActions> {
  String? _busy;

  Future<void> _run(String which) async {
    final l = AppLocalizations.of(context);
    final key = widget.dayKey;
    setState(() => _busy = which);
    try {
      final Map<String, MealEntry>? yesterday = which == 'yesterday'
          ? await ref.read(
              dayGridProvider((
                messId: key.messId,
                day: dayOnly(key.day.subtract(const Duration(hours: 22))),
              )).future,
            )
          : null;
      final now = ref.read(dayGridProvider(key)).value;
      final changes = [
        for (final m in widget.members)
          for (final t in widget.types)
            ?_change(entryOrZero(now, key, m.id, t.id), yesterday),
      ];
      if (changes.isEmpty) {
        if (mounted) showSnack(context, l.mealGridNothingToChange);
        return;
      }
      await ref.read(dayGridProvider(key).notifier).putAll(changes);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// The new value of [e], or null when it would not change.
  MealEntry? _change(MealEntry e, Map<String, MealEntry>? yesterday) {
    final y = yesterday?[cellKey(e.memberId, e.mealTypeId)];
    final next = yesterday == null
        ? e.copyWith(count: 1, isOff: false)
        : e.copyWith(
            count: y?.count ?? 0,
            guestCount: y?.guestCount ?? 0,
            isOff: y?.isOff ?? false,
          );
    final same =
        next.count == e.count &&
        next.guestCount == e.guestCount &&
        next.isOff == e.isOff;
    return same ? null : next;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget action(String which, String label, IconData icon) => AppButton(
      label: label,
      icon: icon,
      variant: AppButtonVariant.secondary,
      loading: _busy == which,
      onPressed: _busy == null ? () => _run(which) : null,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        AppSpace.md,
      ),
      child: Row(
        spacing: AppSpace.sm,
        children: [
          Expanded(child: action('one', l.mealGridAllOne, Icons.done_all)),
          Expanded(
            child: action(
              'yesterday',
              l.mealGridLikeYesterday,
              Icons.content_copy_outlined,
            ),
          ),
          CookShareButton(messId: widget.dayKey.messId),
        ],
      ),
    );
  }
}

/// "এই দিনের মোট মিল" with the day's headcount, large.
class _DayTotal extends ConsumerWidget {
  const _DayTotal({required this.dayKey, required this.types});

  final MessDay dayKey;
  final List<MealType> types;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final total = dayPeople(
      ref.watch(dayGridProvider(dayKey)).value?.values ?? const [],
      types,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        0,
      ),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context).mealGridDayTotal,
                style: text.titleSmall,
              ),
            ),
            Text(
              decimal(total, bangla: bnDigits(context)),
              key: const Key('day-total'),
              style: text.displaySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The selected month: total meals and rate (SQL), then meals per member.
class _MonthSummary extends ConsumerWidget {
  const _MonthSummary({required this.messId, required this.start});

  final String messId;
  final DateTime start;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final key = (messId: messId, start: start);
    final bn = bnDigits(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final current = ref.watch(currentPeriodProvider(messId)).value;
    final summary = ref.watch(periodSummaryProvider(key));
    final title = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xl,
        AppSpace.gutter,
        AppSpace.md,
      ),
      child: Text(l.mealsByMember, style: text.titleMedium),
    );
    if (summary.hasError && !summary.hasValue) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          ErrorView(
            message: failureText(context, summary.error!),
            onRetry: () => ref.invalidate(periodSummaryProvider(key)),
          ),
        ],
      );
    }
    final value = summary.value;
    if (value == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const LoadingView(rows: 3)],
      );
    }
    final (period, t, balances) = value;
    final isCurrent = current != null && current.start == period.start;
    final guests = isCurrent
        ? ref.watch(guestMealsProvider(messId)).value ?? const {}
        : const <String, double>{};
    final rows = balances.where((b) => b.meals > 0).toList()
      ..sort((a, b) => b.meals.compareTo(a.meals));
    final locale = Localizations.localeOf(context).languageCode;
    String date(DateTime d) =>
        Fmt.dateLong(d, locale: locale, banglaDigits: bn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.lg,
            children: [
              Expanded(
                child: Figure(
                  label: l.mealsTotalLabel,
                  value: decimal(t.totalMeals, bangla: bn),
                  proof: l.mealsPeriod(
                    date(period.start),
                    // The period end is exclusive.
                    date(period.end.subtract(const Duration(hours: 12))),
                  ),
                  initiallyExpanded: true,
                ),
              ),
              Expanded(
                child: t.unallocatedFood
                    ? Text(
                        l.todayRateUnallocated(
                          Fmt.money(t.foodTotal, banglaDigits: bn),
                        ),
                        style: text.bodyMedium?.copyWith(color: p.warning),
                      )
                    : Figure(
                        label: l.todayRateLabel,
                        value: Fmt.money(t.mealRate, banglaDigits: bn),
                        proof: l.todayRateProof(
                          Fmt.money(t.foodTotal, banglaDigits: bn),
                          decimal(t.totalMeals, bangla: bn),
                        ),
                        initiallyExpanded: true,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (rows.isEmpty)
          EmptyView(icon: Icons.restaurant_outlined, message: l.mealsEmpty)
        else ...[
          const Divider(),
          for (final b in rows) ...[
            ListTile(
              minTileHeight: AppSize.touch + AppSpace.md,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.gutter,
              ),
              title: Text(b.displayName, style: text.titleSmall),
              subtitle: (guests[b.memberId] ?? 0) > 0
                  ? Text(
                      l.mealsGuestNote(
                        decimal(guests[b.memberId]!, bangla: bn),
                      ),
                    )
                  : null,
              trailing: Text(
                decimal(b.meals, bangla: bn),
                style: text.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MemberMealsScreen(
                    messId: messId,
                    memberId: b.memberId,
                    name: b.displayName,
                    meals: b.meals,
                    period: period,
                  ),
                ),
              ),
            ),
            const Divider(),
          ],
        ],
      ],
    );
  }
}

/// One member's period, day by day, newest first. Read-only.
class MemberMealsScreen extends ConsumerWidget {
  const MemberMealsScreen({
    super.key,
    required this.messId,
    required this.memberId,
    required this.name,
    required this.meals,
    required this.period,
  });

  final String messId;
  final String memberId;
  final String name;

  /// Billable, from SQL `member_balances`.
  final double meals;
  final MonthPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = (
      messId: messId,
      from: period.start,
      to: period.end,
      memberId: memberId,
    );
    final entriesAsync = ref.watch(rangeEntriesProvider(range));
    final typesAsync = ref.watch(mealTypesProvider(messId));

    final error = [
      if (!entriesAsync.hasValue) entriesAsync.error,
      if (!typesAsync.hasValue) typesAsync.error,
    ].nonNulls.firstOrNull;

    final Widget body;
    if (error != null) {
      body = ErrorView(
        message: failureText(context, error),
        onRetry: () {
          ref.invalidate(rangeEntriesProvider(range));
          ref.invalidate(mealTypesProvider(messId));
        },
      );
    } else if (!entriesAsync.hasValue || !typesAsync.hasValue) {
      body = const LoadingView(rows: 6);
    } else {
      body = _DayList(
        name: name,
        meals: meals,
        entries: entriesAsync.value!,
        types: typesAsync.value!,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: body,
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({
    required this.name,
    required this.meals,
    required this.entries,
    required this.types,
  });

  final String name;
  final double meals;
  final List<MealEntry> entries;
  final List<MealType> types;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final bn = bnDigits(context);
    final locale = Localizations.localeOf(context).languageCode;
    if (entries.isEmpty) {
      return EmptyView(
        icon: Icons.restaurant_outlined,
        message: l.mealsMemberEmpty(name),
      );
    }
    final byDay = <DateTime, Map<String, MealEntry>>{};
    for (final e in entries) {
      (byDay[dayOnly(e.date)] ??= {})[e.mealTypeId] = e;
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final shown = types
        .where((t) => t.enabled || entries.any((e) => e.mealTypeId == t.id))
        .toList();
    final now = today();
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpace.xl),
      itemCount: days.length + 1,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.lg,
              AppSpace.gutter,
              AppSpace.sm,
            ),
            child: Row(
              spacing: AppSpace.xs,
              children: [
                Expanded(
                  child: Text(
                    l.mealsMemberTotal(decimal(meals, bangla: bn)),
                    style: text.titleMedium,
                  ),
                ),
                for (final t in shown)
                  SizedBox(
                    width: AppSize.mealCellWidth,
                    child: Text(
                      t.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium,
                    ),
                  ),
              ],
            ),
          );
        }
        final d = days[i - 1];
        final row = byDay[d]!;
        final total = row.values.fold(0.0, (s, e) => s + e.people);
        final date = Fmt.dateLong(d, locale: locale, banglaDigits: bn);
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.gutter,
            vertical: AppSpace.xs,
          ),
          child: Row(
            spacing: AppSpace.xs,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: text.titleSmall),
                    Text(
                      Fmt.meals(total, banglaDigits: bn),
                      style: text.labelSmall?.copyWith(
                        color: p.inkTertiary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              for (final t in shown)
                MealCell(
                  label: '$date ${t.name}',
                  count: row[t.id]?.count ?? 0,
                  guests: row[t.id]?.guestCount ?? 0,
                  off: row[t.id]?.isOff ?? false,
                  today: d == now,
                  banglaDigits: bn,
                ),
            ],
          ),
        );
      },
    );
  }
}
