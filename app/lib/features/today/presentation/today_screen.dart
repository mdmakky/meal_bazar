import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/db/sync.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../ai/presentation/ai_entry.dart';
import '../../duty/presentation/today_duty_card.dart';
import '../../meals/application/meal_providers.dart';
import '../../meals/domain/meal.dart';
import '../../meals/presentation/meal_grid.dart';
import '../../meals/presentation/meal_widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../money/application/money_providers.dart';
import '../../money/presentation/money_sheets.dart';
import '../../month/application/month_providers.dart';
import '../../notices/presentation/latest_notice_banner.dart';
import '../../recurring/presentation/recurring_screen.dart';
import '../application/day_grid.dart';
import 'dashboard.dart';
import 'setup_checklist.dart';

/// হোম: (managers) the setup checklist, the date, the day's headcount with its
/// proof, the month's meal rate with its proof, the day's meals in brief
/// (entered on the মিল tab), quick actions; then the month dashboard.
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
    final mess = ref.watch(currentMessProvider);
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
          if (manager)
            SliverToBoxAdapter(child: SetupChecklist(messId: messId)),
          const SliverToBoxAdapter(child: LatestNoticeBanner()),
          const SliverToBoxAdapter(child: RecurringPromptCard()),
          SliverToBoxAdapter(
            child: _Header(
              day: _day,
              dayKey: key,
              types: types,
              onShift: _shift,
              onToday: () => setState(() => _day = today()),
            ),
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
            if (manager) SliverToBoxAdapter(child: _AiEntry(day: _day)),
            SliverToBoxAdapter(
              child: _DayMeals(dayKey: key, types: types),
            ),
            const SliverToBoxAdapter(child: TodayDutyCard()),
            if (myId != null && mess != null)
              SliverToBoxAdapter(
                child: MealOffHint(cutoff: mess.mealOffCutoff),
              ),
          ],
          if (hasMembers)
            SliverToBoxAdapter(
              child: MonthDashboard(messId: messId, manager: manager),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xl)),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(onRefresh: refresh, child: body),
      ),
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
          SyncLine(messId: dayKey.messId),
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

/// "আজকের মিল": per meal type headcount and the day total, and the way
/// into the মিল tab where meals are entered.
class _DayMeals extends ConsumerWidget {
  const _DayMeals({required this.dayKey, required this.types});

  final MessDay dayKey;
  final List<MealType> types;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final bn = bnDigits(context);
    final entries =
        ref.watch(dayGridProvider(dayKey)).value?.values ?? const [];
    final isToday = dayKey.day == today();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isToday ? l.mealGridToday : l.mealGridDayTotal,
                    style: text.titleSmall,
                  ),
                ),
                Text(
                  decimal(dayPeople(entries, types), bangla: bn),
                  style: text.headlineSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Text(
              [
                for (final t in types)
                  '${t.name} ${decimal(dayPeople(entries, [t]), bangla: bn)}',
              ].join(' · '),
              style: text.bodyMedium?.copyWith(color: p.inkSecondary),
            ),
            AppButton(
              label: l.mealGridGoToMeals,
              icon: Icons.restaurant_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go('/meals'),
            ),
          ],
        ),
      ),
    );
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
              () => addGuest(context, ref, dayKey, members, types),
            ),
            action(
              l.todayActionMealOff,
              Icons.no_meals_outlined,
              () => markMealOff(context, ref, dayKey, members, types),
            ),
          ],
        ),
      ),
    );
  }
}
