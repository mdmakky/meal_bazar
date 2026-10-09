import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/db/sync.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/platform/platform_widgets.dart';
import '../../../core/widgets/widgets.dart';
import '../../audit/application/audit_providers.dart';
import '../../duty/presentation/today_duty_card.dart';
import '../../meals/application/meal_providers.dart';
import '../../meals/domain/meal.dart';
import '../../meals/presentation/meal_grid.dart';
import '../../meals/presentation/meals_screen.dart' show showAddChooser;
import '../../meals/presentation/meal_widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../messages/application/message_providers.dart';
import '../../messages/application/unread_provider.dart';
import '../../messages/presentation/message_shortcuts.dart';
import '../../money/application/money_providers.dart';
import '../../money/presentation/money_screen.dart'
    show balanceWord, showBillSheet;
import '../../month/application/month_providers.dart';
import '../../notices/presentation/latest_notice_banner.dart';
import '../application/day_grid.dart';
import 'dashboard.dart';
import 'setup_checklist.dart';

/// হোম, by role. Manager: the setup checklist, the day's statement card
/// (headcount, meal rate), then what needs them, the fund, who owes; one "+"
/// for adding anything. Member: my balance card, my meals today with the
/// meal-off switches, then everyone's account and entries about me.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  DateTime _day = today();

  void _shift(int days) =>
      setState(() => _day = dayOnly(_day.add(Duration(days: days, hours: 2))));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null) return const Scaffold(body: LoadingView());

    final key = (messId: messId, day: _day);
    // Queued writes reached the server: the SQL figures changed.
    ref.listen(syncQueueProvider, (prev, next) {
      if ((prev?.value?.isNotEmpty ?? false) && next.value?.isEmpty == true) {
        monthProviders(messId).forEach(ref.invalidate);
      }
    });
    final manager = ref.watch(amIManagerProvider);
    final myId = plainMemberId(ref);
    final membersAsync = ref.watch(membersProvider(messId));
    final typesAsync = ref.watch(mealTypesProvider(messId));
    final gridAsync = ref.watch(dayGridProvider(key));

    void retry() {
      ref.invalidate(membersProvider(messId));
      ref.invalidate(mealTypesProvider(messId));
      ref.invalidate(dayEntriesProvider(key));
      monthProviders(messId).forEach(ref.invalidate);
    }

    Future<void> refresh() async {
      retry();
      ref.invalidate(currentPeriodProvider(messId));
      ref.invalidate(bazarsProvider(messId));
      ref.invalidate(depositsProvider(messId));
      ref.invalidate(myActivityProvider(messId));
      ref.invalidate(unreadMessagesCountProvider(messId));
      ref.invalidate(unreadSplitProvider(messId));
      ref.invalidate(mealOffDeadlinesProvider);
      ref.invalidate(dayEntriesProvider);
      // Each section shows its own error; the spinner only waits.
      await Future.wait([
        ref.read(membersProvider(messId).future),
        ref.read(monthTotalsProvider(messId).future),
      ]).catchError((_) => const <Object>[]);
    }

    final error = [
      if (!membersAsync.hasValue) membersAsync.error,
      if (!typesAsync.hasValue) typesAsync.error,
      if (!gridAsync.hasValue) gridAsync.error,
    ].nonNulls.firstOrNull;

    final Widget body;
    List<Member> rows = const [];
    List<MealType> types = const [];
    if (error != null) {
      body = ErrorView(message: failureText(context, error), onRetry: retry);
    } else if (!membersAsync.hasValue ||
        !typesAsync.hasValue ||
        !gridAsync.hasValue) {
      body = const LoadingView(rows: 5);
    } else {
      (:rows, :types) = gridShape(
        membersAsync.value!,
        typesAsync.value!,
        gridAsync.value!.values,
        _day,
      );
      final hasMembers = membersAsync.value!.any(
        (m) => m.status != MemberStatus.pending,
      );
      body = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: PlatformBanner()),
          if (manager && ref.featureOn('setup_checklist'))
            SliverToBoxAdapter(child: SetupChecklist(messId: messId)),
          const SliverToBoxAdapter(child: LatestNoticeBanner()),
          SliverToBoxAdapter(
            child: manager
                ? _TodayHero(
                    day: _day,
                    dayKey: key,
                    types: types,
                    onShift: _shift,
                    onToday: () => setState(() => _day = today()),
                  )
                : _MemberHero(messId: messId),
          ),
          SliverToBoxAdapter(
            child: MessageShortcuts(messId: messId, manager: manager),
          ),
          if (!hasMembers)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.group_outlined,
                message: l.todayNoMembers,
                actionLabel: manager ? l.membersAdd : null,
                onAction: () => context.push('/more/members'),
              ),
            )
          else if (types.isEmpty)
            SliverToBoxAdapter(
              child: EmptyView(
                icon: Icons.restaurant_outlined,
                message: l.todayNoMealTypes,
                actionLabel: manager ? l.todayNoMealTypesAction : null,
                onAction: () => context.push('/more/meal-types'),
              ),
            )
          else ...[
            if (myId != null)
              SliverToBoxAdapter(
                child: _MyToday(dayKey: key, types: types),
              ),
            const SliverToBoxAdapter(child: TodayDutyCard()),
          ],
          if (hasMembers)
            SliverToBoxAdapter(
              child: MonthDashboard(messId: messId, manager: manager),
            ),
          // Room for the FAB over the last card.
          const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxxl * 2)),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(onRefresh: refresh, child: body),
      ),
      floatingActionButton: manager && rows.isNotEmpty && types.isNotEmpty
          ? PressableScale(
              haptic: true,
              child: FloatingActionButton(
                tooltip: l.mealGridAdd,
                onPressed: () => showAddChooser(context, ref, key, rows, types),
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }
}

/// The statement card: the day (with its switcher and sync state), the day's
/// headcount with its proof, the month's meal rate with its proof, and the
/// way into the মিল tab. Figures roll when they change.
class _TodayHero extends ConsumerWidget {
  const _TodayHero({
    required this.day,
    required this.dayKey,
    required this.types,
    required this.onShift,
    required this.onToday,
  });

  final DateTime day;
  final MessDay dayKey;
  final List<MealType> types;
  final ValueChanged<int> onShift;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final now = today();
    final isToday = day == now;
    final mess = ref.watch(currentMessProvider);
    final bn = bnDigits(context);
    final date = Fmt.dateLong(
      day,
      locale: Localizations.localeOf(context).languageCode,
      banglaDigits: bn,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        AppSpace.lg,
      ),
      child: AppCard.ink(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xl,
          AppSpace.md,
          AppSpace.sm,
          AppSpace.xl,
        ),
        child: Builder(
          // Inside the card: the statement theme's text and palette.
          builder: (context) {
            final text = Theme.of(context).textTheme;
            final p = context.palette;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: isToday ? null : onToday,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpace.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(date, style: text.titleMedium),
                              Row(
                                spacing: AppSpace.sm,
                                children: [
                                  if (isToday)
                                    Container(
                                      width: AppSize.dot,
                                      height: AppSize.dot,
                                      decoration: BoxDecoration(
                                        color: p.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Flexible(
                                    child: Text(
                                      [
                                        isToday
                                            ? l.todayIsToday
                                            : l.todayBackToToday,
                                        ?mess?.name,
                                      ].join(' · '),
                                      overflow: TextOverflow.ellipsis,
                                      style: text.labelSmall?.copyWith(
                                        color: isToday ? p.accent : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l.todayPrevDay,
                      onPressed: () => onShift(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: l.todayNextDay,
                      // Planning ahead: tomorrow at most.
                      onPressed: day.isBefore(now) || isToday
                          ? () => onShift(1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SyncLine(messId: dayKey.messId),
                ),
                const SizedBox(height: AppSpace.lg),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Headcount(
                        dayKey: dayKey,
                        types: types,
                        isToday: isToday,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.lg,
                        ),
                        child: Divider(height: 1, color: p.surfaceInkBorder),
                      ),
                      _Rate(messId: dayKey.messId),
                      const SizedBox(height: AppSpace.xl),
                      AppButton(
                        label: l.mealGridGoToMeals,
                        icon: Icons.restaurant_outlined,
                        expand: true,
                        onPressed: () => context.go('/meals'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Overline, rolling figure, proof: one block of the statement card.
class _HeroFigure extends StatelessWidget {
  const _HeroFigure({required this.label, this.figure, this.proof});

  final String label;
  final Widget? figure;
  final Widget? proof;

  @override
  Widget build(BuildContext context) {
    final figure = this.figure;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.xs,
        children: [
          Text(label, style: AppType.overline(context)),
          if (figure != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: figure,
            ),
          ?proof,
        ],
      ),
    );
  }
}

Widget _proof(BuildContext context, String s, {Color? color}) => Text(
  s,
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: color ?? context.palette.inkSecondary,
    fontFeatures: const [FontFeature.tabularFigures()],
  ),
);

class _Headcount extends ConsumerWidget {
  const _Headcount({
    required this.dayKey,
    required this.types,
    required this.isToday,
  });

  final MessDay dayKey;
  final List<MealType> types;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final entries =
        ref.watch(dayGridProvider(dayKey)).value?.values ?? const [];
    // Display-only headcount of the day; billing comes from SQL.
    final guests = entries
        .where((e) => types.any((t) => t.id == e.mealTypeId))
        .fold(0, (s, e) => s + e.guestCount);
    final proof = [
      for (final t in types)
        '${t.name} ${Fmt.meals(dayPeople(entries, [t]), banglaDigits: bn)}',
      if (guests > 0) l.todayGuestsProof(Fmt.digits('$guests', bangla: bn)),
    ].join(' · ');
    return _HeroFigure(
      label: isToday ? l.todayHeadcountLabel : l.todayDayHeadcountLabel,
      figure: RollingNumber.meals(
        dayPeople(entries, types),
        banglaDigits: bn,
        style: Theme.of(context).textTheme.displayLarge,
      ),
      proof: types.isEmpty ? null : _proof(context, proof),
    );
  }
}

class _Rate extends ConsumerWidget {
  const _Rate({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    // Secondary figure: while loading or failed, the grid still works.
    final t = ref.watch(monthTotalsProvider(messId)).value;
    if (t == null) return const SizedBox.shrink();
    final food = Fmt.money(t.foodTotal, banglaDigits: bn);
    if (t.unallocatedFood) {
      return _HeroFigure(
        label: l.todayRateLabel,
        proof: _proof(
          context,
          l.todayRateUnallocated(food),
          color: context.palette.warning,
        ),
      );
    }
    return _HeroFigure(
      label: l.todayRateLabel,
      figure: RollingNumber.money(
        t.mealRate,
        banglaDigits: bn,
        style: Theme.of(context).textTheme.displaySmall,
      ),
      proof: _proof(
        context,
        t.fixedRate
            ? l.rateFixed
            : l.todayRateProof(food, Fmt.meals(t.totalMeals, banglaDigits: bn)),
      ),
    );
  }
}

/// Member statement card: my balance this month (SQL), my meals, the rate,
/// and the way into my bill.
class _MemberHero extends ConsumerWidget {
  const _MemberHero({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final myId = ref.watch(currentMembershipProvider)?.member.id;
    final mess = ref.watch(currentMessProvider);
    final balances = ref.watch(memberBalancesProvider(messId));
    final rate = ref.watch(monthTotalsProvider(messId)).value;
    final me = balances.value?.where((b) => b.memberId == myId).firstOrNull;
    final date = Fmt.dateLong(
      today(),
      locale: Localizations.localeOf(context).languageCode,
      banglaDigits: bn,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        AppSpace.lg,
      ),
      child: AppCard.ink(
        child: Builder(
          // Inside the card: the statement theme's text and palette.
          builder: (context) {
            final text = Theme.of(context).textTheme;
            final p = context.palette;
            Widget pending(TextStyle? style) => Text('…', style: style);
            final Widget balance;
            if (balances.hasError && !balances.hasValue) {
              balance = _HeroFigure(
                label: l.mineBalance,
                proof: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(memberBalancesProvider(messId)),
                    child: Text(l.retry),
                  ),
                ),
              );
            } else if (!balances.hasValue) {
              balance = _HeroFigure(
                label: l.mineBalance,
                figure: pending(text.displayLarge),
              );
            } else if (me == null) {
              balance = _HeroFigure(
                label: l.mineBalance,
                proof: _proof(context, l.dashNotInMonth),
              );
            } else {
              final c = me.closingBalance;
              balance = _HeroFigure(
                label: l.mineBalance,
                figure: RollingNumber.money(
                  c,
                  signed: true,
                  banglaDigits: bn,
                  style: text.displayLarge,
                ),
                proof: _proof(context, balanceWord(l, c)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(date, style: text.titleMedium),
                Row(
                  spacing: AppSpace.sm,
                  children: [
                    Container(
                      width: AppSize.dot,
                      height: AppSize.dot,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        [l.todayIsToday, ?mess?.name].join(' · '),
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(color: p.accent),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SyncLine(messId: messId),
                ),
                const SizedBox(height: AppSpace.lg),
                balance,
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                  child: Divider(height: 1, color: p.surfaceInkBorder),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.lg,
                  children: [
                    Expanded(
                      child: _HeroFigure(
                        label: l.dashMyMeals,
                        figure: me == null
                            ? pending(text.displaySmall)
                            : RollingNumber.meals(
                                me.meals,
                                banglaDigits: bn,
                                style: text.displaySmall,
                              ),
                      ),
                    ),
                    Expanded(
                      child: _HeroFigure(
                        label: l.dashRate,
                        figure: rate == null
                            ? pending(text.displaySmall)
                            : RollingNumber.money(
                                rate.mealRate,
                                banglaDigits: bn,
                                style: text.displaySmall,
                              ),
                      ),
                    ),
                  ],
                ),
                if (me != null) ...[
                  const SizedBox(height: AppSpace.xl),
                  AppButton(
                    label: l.dashExplain,
                    icon: Icons.receipt_long_outlined,
                    expand: true,
                    onPressed: () => showBillSheet(context, messId, me),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Member: my meals today, then tomorrow, each with its off/on switch and
/// the SQL deadline ("সন্ধ্যা ৭টা পর্যন্ত"); past it the switch is disabled.
class _MyToday extends ConsumerWidget {
  const _MyToday({required this.dayKey, required this.types});

  final MessDay dayKey;
  final List<MealType> types;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final myId = plainMemberId(ref);
    if (myId == null) return const SizedBox.shrink();
    final d = dayKey.day;
    final tomorrow = (
      messId: dayKey.messId,
      day: DateTime(d.year, d.month, d.day + 1),
    );
    final enabled = types.where((t) => t.enabled).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        AppSpace.lg,
      ),
      child: AppCard.raised(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.sm,
          AppSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l.myTodayTitle, style: text.titleMedium),
            ),
            for (final t in enabled)
              _MyMealRow(dayKey: dayKey, type: t, memberId: myId),
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpace.md,
                bottom: AppSpace.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l.myTomorrow,
                  style: text.labelLarge?.copyWith(color: p.inkSecondary),
                ),
              ),
            ),
            for (final t in enabled)
              _MyMealRow(dayKey: tomorrow, type: t, memberId: myId),
          ],
        ),
      ),
    );
  }
}

/// One meal of mine on a day: name, deadline line, my count, switch.
class _MyMealRow extends ConsumerWidget {
  const _MyMealRow({
    required this.dayKey,
    required this.type,
    required this.memberId,
  });

  final MessDay dayKey;
  final MealType type;
  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final grid = ref.watch(dayGridProvider(dayKey)).value;
    final e = entryOrZero(grid, dayKey, memberId, type.id);
    final canOff = ownOffId(ref) != null;
    final open = canOff && mealOffOpen(ref, dayKey, type.id);
    final deadline = mealOffDeadlineOf(ref, dayKey, type.id);
    final note = [
      if (e.guestCount > 0)
        l.todayGuestsProof(Fmt.digits('${e.guestCount}', bangla: bn)),
      if (canOff && !open)
        l.mealOffCutoffPassed
      else if (canOff && deadline != null)
        deadlineText(context, deadline, ref.watch(nowProvider)()),
    ].join(' · ');
    final VoidCallback? toggle = open
        ? () => putEntry(context, ref, dayKey, toggleMealOff(e), own: true)
        : null;

    return MergeSemantics(
      key: ValueKey('my-${isoDate(dayKey.day)}-${type.id}'),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: toggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.touch + 8),
          child: Row(
            spacing: AppSpace.sm,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type.name, style: text.bodyLarge),
                    if (note.isNotEmpty)
                      Text(
                        note,
                        style: text.bodySmall?.copyWith(color: p.inkSecondary),
                      ),
                  ],
                ),
              ),
              Text(
                e.isOff
                    ? l.myMealOff
                    : l.myMealCount(Fmt.meals(e.count, banglaDigits: bn)),
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: e.isOff ? p.inkTertiary : p.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (canOff)
                Switch(
                  value: !e.isOff,
                  onChanged: toggle == null ? null : (_) => toggle(),
                )
              else
                const SizedBox(width: AppSpace.sm),
            ],
          ),
        ),
      ),
    );
  }
}
