import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../ai/presentation/ai_entry.dart';
import '../../meals/application/meal_providers.dart';
import '../../meals/domain/meal.dart';
import '../../meals/presentation/meal_widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
import '../../money/presentation/money_sheets.dart';
import '../../month/application/month_providers.dart';
import '../application/day_grid.dart';

/// The daily routine: date, the day's headcount with its proof, the month's
/// meal rate with its proof, the member × meal grid, quick actions.
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
    final manager = ref.watch(amIManagerProvider);
    final membersAsync = ref.watch(membersProvider(messId));
    final typesAsync = ref.watch(mealTypesProvider(messId));
    // Only the grid's shape: a cell tap must not rebuild the whole screen.
    final (gridLoaded, gridError) = ref.watch(
      dayGridProvider(key).select((a) => (a.hasValue, a.error)),
    );
    final (empty, typesUsed, membersUsed) = ref.watch(
      dayGridProvider(key).select((a) {
        final v = a.value?.values ?? const <MealEntry>[];
        String ids(Iterable<String> s) =>
            (s.toSet().toList()..sort()).join(',');
        return (
          v.isEmpty,
          ids(v.map((e) => e.mealTypeId)),
          ids(v.map((e) => e.memberId)),
        );
      }),
    );

    void retry() {
      ref.invalidate(membersProvider(messId));
      ref.invalidate(mealTypesProvider(messId));
      ref.invalidate(dayEntriesProvider(key));
      ref.invalidate(monthTotalsProvider(messId));
    }

    final error = [
      if (!membersAsync.hasValue) membersAsync.error,
      if (!typesAsync.hasValue) typesAsync.error,
      if (!gridLoaded) gridError,
    ].nonNulls.firstOrNull;

    final Widget body;
    List<Member> rows = const [];
    List<MealType> types = const [];
    if (error != null) {
      body = ErrorView(message: failureText(context, error), onRetry: retry);
    } else if (!membersAsync.hasValue || !typesAsync.hasValue || !gridLoaded) {
      body = const LoadingView(rows: 5);
    } else {
      // Members present that day, plus anyone who already has a row.
      rows = membersAsync.value!.where((m) {
        final present =
            m.status == MemberStatus.active &&
            !m.joinedOn.isAfter(_day) &&
            (m.leftOn == null || _day.isBefore(m.leftOn!));
        return present ||
            (m.status != MemberStatus.pending &&
                membersUsed.split(',').contains(m.id));
      }).toList();
      // Disabled types stay visible on days they still have rows.
      types = typesAsync.value!
          .where((t) => t.enabled || typesUsed.split(',').contains(t.id))
          .toList();
      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              day: _day,
              dayKey: key,
              types: types,
              onShift: _shift,
              onToday: () => setState(() => _day = today()),
            ),
          ),
          if (rows.isEmpty)
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.restaurant_outlined,
                message: l.todayNoMealTypes,
                actionLabel: manager ? l.todayNoMealTypesAction : null,
                onAction: () => context.push('/more/meal-types'),
              ),
            )
          else ...[
            if (manager) SliverToBoxAdapter(child: _AiEntry(day: _day)),
            if (empty)
              SliverToBoxAdapter(
                child: _FillCard(dayKey: key, manager: manager),
              )
            else
              SliverMainAxisGroup(
                slivers: [
                  PinnedHeaderSliver(
                    child: _GridHeader(dayKey: key, types: types),
                  ),
                  SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, i) => _MemberRow(
                      dayKey: key,
                      member: rows[i],
                      types: types,
                      editable: manager,
                    ),
                  ),
                ],
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xl)),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: manager && rows.isNotEmpty && types.isNotEmpty
          ? _QuickActions(dayKey: key, members: rows, types: types)
          : null,
    );
  }
}

/// Date switcher, then the two headline figures.
class _Header extends ConsumerWidget {
  const _Header({
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
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final bn = bnDigits(context);
    final now = today();
    final isToday = day == now;
    final mess = ref.watch(currentMessProvider);

    final date = Fmt.dateLong(
      day,
      locale: Localizations.localeOf(context).languageCode,
      banglaDigits: bn,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xs,
        AppSpace.sm,
        AppSpace.xs,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l.todayPrevDay,
                onPressed: () => onShift(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: isToday ? null : onToday,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                    child: Column(
                      children: [
                        Text(
                          date,
                          style: text.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                  isToday ? l.todayIsToday : l.todayBackToToday,
                                  ?mess?.name,
                                ].join(' · '),
                                overflow: TextOverflow.ellipsis,
                                style: text.labelSmall,
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
                tooltip: l.todayNextDay,
                // Planning ahead: tomorrow at most.
                onPressed: day.isBefore(now) || isToday
                    ? () => onShift(1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.lg,
              children: [
                Expanded(
                  child: _HeadcountFigure(
                    dayKey: dayKey,
                    types: types,
                    isToday: isToday,
                  ),
                ),
                Expanded(child: _RateFigure(messId: dayKey.messId)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadcountFigure extends ConsumerWidget {
  const _HeadcountFigure({
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
    double people(String typeId) => entries
        .where((e) => e.mealTypeId == typeId)
        .fold(0.0, (s, e) => s + e.people);
    final total = types.fold(0.0, (s, t) => s + people(t.id));
    final guests = entries
        .where((e) => types.any((t) => t.id == e.mealTypeId))
        .fold(0, (s, e) => s + e.guestCount);
    final proof = [
      for (final t in types)
        '${t.name} ${Fmt.meals(people(t.id), banglaDigits: bn)}',
      if (guests > 0) l.todayGuestsProof(Fmt.digits('$guests', bangla: bn)),
    ].join(' · ');
    return Figure(
      label: isToday ? l.todayHeadcountLabel : l.todayDayHeadcountLabel,
      value: Fmt.meals(total, banglaDigits: bn),
      proof: types.isEmpty ? null : proof,
      initiallyExpanded: true,
    );
  }
}

class _RateFigure extends ConsumerWidget {
  const _RateFigure({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final bn = bnDigits(context);
    // Secondary figure: while loading or failed, the grid still works.
    final t = ref.watch(monthTotalsProvider(messId)).value;
    if (t == null) return const SizedBox.shrink();
    final food = Fmt.money(t.foodTotal, banglaDigits: bn);
    if (t.unallocatedFood) {
      final text = Theme.of(context).textTheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.xs,
        children: [
          Text(l.todayRateLabel, style: text.bodyMedium),
          Text(
            l.todayRateUnallocated(food),
            style: text.bodyMedium?.copyWith(color: p.warning),
          ),
        ],
      );
    }
    return Figure(
      label: l.todayRateLabel,
      value: Fmt.money(t.mealRate, banglaDigits: bn),
      proof: l.todayRateProof(food, decimal(t.totalMeals, bangla: bn)),
      initiallyExpanded: true,
    );
  }
}

/// Quiet way into AI meal drafts; the draft is reviewed before saving.
class _AiEntry extends StatelessWidget {
  const _AiEntry({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        AppSpace.lg,
      ),
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.border),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => showMealDraftSheet(context, day: day),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              child: Row(
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
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).todayAiEntry,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: p.inkTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// No rows for the day yet. Manager fills from yesterday (else 1 each).
class _FillCard extends ConsumerStatefulWidget {
  const _FillCard({required this.dayKey, required this.manager});

  final MessDay dayKey;
  final bool manager;

  @override
  ConsumerState<_FillCard> createState() => _FillCardState();
}

class _FillCardState extends ConsumerState<_FillCard> {
  var _busy = false;

  Future<void> _fill() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(mealControllerProvider)
          .fillDay(widget.dayKey.messId, widget.dayKey.day);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final isToday = widget.dayKey.day == today();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            Text(
              widget.manager ? l.todayNoEntries : l.todayNoEntriesMember,
              style: text.titleSmall,
            ),
            if (widget.manager) ...[
              Text(l.todayFillHelp, style: text.bodyMedium),
              AppButton(
                label: isToday ? l.todayFill : l.todayFillDay,
                icon: Icons.playlist_add_check,
                loading: _busy,
                onPressed: _fill,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const _cellGap = AppSpace.xs;

/// Pinned: meal type names with the column's headcount.
class _GridHeader extends ConsumerWidget {
  const _GridHeader({required this.dayKey, required this.types});

  final MessDay dayKey;
  final List<MealType> types;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = bnDigits(context);
    final entries =
        ref.watch(dayGridProvider(dayKey)).value?.values ?? const [];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        border: Border.symmetric(horizontal: BorderSide(color: p.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.gutter,
          vertical: AppSpace.sm,
        ),
        child: Row(
          spacing: _cellGap,
          children: [
            Expanded(child: Text(l.todayMemberColumn, style: text.labelMedium)),
            for (final t in types)
              SizedBox(
                width: AppSize.mealCellWidth,
                child: Column(
                  children: [
                    Text(
                      t.name,
                      style: text.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      Fmt.meals(
                        entries
                            .where((e) => e.mealTypeId == t.id)
                            .fold(0.0, (s, e) => s + e.people),
                        banglaDigits: bn,
                      ),
                      style: text.labelSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ponytail: fixed 52 dp columns fit ~4 meal types on a 360 dp phone; scroll
// the cells horizontally if messes really run 5+.
class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.dayKey,
    required this.member,
    required this.types,
    required this.editable,
  });

  final MessDay dayKey;
  final Member member;
  final List<MealType> types;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = bnDigits(context);
    final dayTotal = ref.watch(
      dayGridProvider(dayKey).select(
        (a) => (a.value?.values ?? const <MealEntry>[])
            .where((e) => e.memberId == member.id)
            .fold(0.0, (s, e) => s + e.people),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.gutter,
          vertical: AppSpace.xs,
        ),
        child: Row(
          spacing: _cellGap,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    Fmt.meals(dayTotal, banglaDigits: bn),
                    style: text.labelSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            for (final t in types)
              _Cell(
                dayKey: dayKey,
                member: member,
                type: t,
                editable: editable,
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends ConsumerWidget {
  const _Cell({
    required this.dayKey,
    required this.member,
    required this.type,
    required this.editable,
  });

  final MessDay dayKey;
  final Member member;
  final MealType type;
  final bool editable;

  MealEntry _current(WidgetRef ref) =>
      ref.read(dayGridProvider(dayKey)).value?[cellKey(member.id, type.id)] ??
      MealEntry(
        memberId: member.id,
        mealTypeId: type.id,
        date: dayKey.day,
        count: 0,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = cellKey(member.id, type.id);
    final v = ref.watch(
      dayGridProvider(dayKey).select((a) {
        final e = a.value?[k];
        return e == null ? null : (e.count, e.guestCount, e.isOff);
      }),
    );
    return MealCell(
      label: '${member.displayName} ${type.name}',
      count: v?.$1 ?? 0,
      guests: v?.$2 ?? 0,
      off: v?.$3 ?? false,
      banglaDigits: bnDigits(context),
      onTap: editable
          ? () => putEntry(context, ref, dayKey, cycleMeal(_current(ref)))
          : null,
      onLongPress: editable
          ? () async {
              final e = await showMealEntrySheet(
                context,
                title: '${member.displayName} · ${type.name}',
                entry: _current(ref),
              );
              if (e != null && context.mounted) {
                await putEntry(context, ref, dayKey, e);
              }
            }
          : null,
    );
  }
}

/// Optimistic save; on failure the cell has reverted, so just say why.
Future<bool> putEntry(
  BuildContext context,
  WidgetRef ref,
  MessDay dayKey,
  MealEntry e,
) async {
  try {
    await ref.read(dayGridProvider(dayKey).notifier).put(e);
    return true;
  } catch (err) {
    if (context.mounted) showFailure(context, err);
    return false;
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({
    required this.dayKey,
    required this.members,
    required this.types,
  });

  final MessDay dayKey;
  final List<Member> members;
  final List<MealType> types;

  /// Member, then meal type (skipped when there is only one).
  Future<MealEntry?> _pick(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final active = types.where((t) => t.enabled).toList();
    final member = await pickOne<Member>(
      context,
      title: l.todayPickMember,
      options: [for (final m in members) (m, m.displayName)],
    );
    if (member == null || !context.mounted) return null;
    final type = active.length == 1
        ? active.single
        : await pickOne<MealType>(
            context,
            title: l.todayPickMealType,
            options: [for (final t in active) (t, t.name)],
          );
    if (type == null) return null;
    return ref.read(dayGridProvider(dayKey)).value?[cellKey(
          member.id,
          type.id,
        )] ??
        MealEntry(
          memberId: member.id,
          mealTypeId: type.id,
          date: dayKey.day,
          count: 0,
        );
  }

  String _names(MealEntry e) =>
      '${members.firstWhere((m) => m.id == e.memberId).displayName} · '
      '${types.firstWhere((t) => t.id == e.mealTypeId).name}';

  Future<void> _guest(BuildContext context, WidgetRef ref) async {
    final current = await _pick(context, ref);
    if (current == null || !context.mounted) return;
    final e = await showMealEntrySheet(
      context,
      title: _names(current),
      entry: current,
      guestsFirst: true,
    );
    if (e != null && context.mounted) await putEntry(context, ref, dayKey, e);
  }

  Future<void> _mealOff(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final current = await _pick(context, ref);
    if (current == null || !context.mounted) return;
    final ok = await putEntry(
      context,
      ref,
      dayKey,
      current.copyWith(isOff: true, count: 0),
    );
    if (ok && context.mounted) {
      final member = members.firstWhere((m) => m.id == current.memberId);
      final type = types.firstWhere((t) => t.id == current.mealTypeId);
      showSnack(context, l.todayMealOffDone(member.displayName, type.name));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    Widget action(String label, IconData icon, VoidCallback onTap) => AppButton(
      label: label,
      icon: icon,
      variant: AppButtonVariant.secondary,
      onPressed: onTap,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.bg,
        border: Border(top: BorderSide(color: context.palette.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.gutter,
          vertical: AppSpace.md,
        ),
        child: Row(
          spacing: AppSpace.sm,
          children: [
            action(
              l.todayActionBazar,
              Icons.shopping_basket_outlined,
              () => showAddBazarSheet(context),
            ),
            action(
              l.todayActionExpense,
              Icons.receipt_long_outlined,
              () => showAddExpenseSheet(context),
            ),
            action(
              l.todayActionDeposit,
              Icons.savings_outlined,
              () => showAddDepositSheet(context),
            ),
            action(
              l.todayActionGuest,
              Icons.person_add_alt,
              () => _guest(context, ref),
            ),
            action(
              l.todayActionMealOff,
              Icons.no_meals_outlined,
              () => _mealOff(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
