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
          const SliverToBoxAdapter(child: PlatformBanner()),
          if (manager && ref.featureOn('setup_checklist'))
            SliverToBoxAdapter(child: SetupChecklist(messId: messId)),
          const SliverToBoxAdapter(child: LatestNoticeBanner()),
          const SliverToBoxAdapter(child: RecurringPromptCard()),
          SliverToBoxAdapter(
            child: _TodayHero(
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
            if (manager &&
                ref.watch(platformConfigProvider.select((c) => c.aiMealDraft)))
              SliverToBoxAdapter(child: _AiEntry(day: _day)),
            const SliverToBoxAdapter(child: TodayDutyCard()),
            if (myId != null &&
                mess != null &&
                ref.featureOn('member_meal_off'))
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
      figure: RollingNumber(
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
            : l.todayRateProof(food, decimal(t.totalMeals, bangla: bn)),
      ),
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
      child: PressableScale(
        scale: 0.98,
        child: AppCard.raised(
          onTap: () => showMealDraftSheet(context, day: day),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Row(
            spacing: AppSpace.md,
            children: [
              Icon(Icons.auto_awesome_outlined, color: p.accent),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).todayAiEntry,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: p.inkSecondary),
                ),
              ),
              Icon(Icons.chevron_right, color: p.inkTertiary),
            ],
          ),
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
    return ColoredBox(
      color: context.palette.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.md,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.sm,
            children: [
              _ActionTile(
                l.todayActionBazar,
                Icons.shopping_basket_outlined,
                () => showAddBazarSheet(context),
              ),
              _ActionTile(
                l.todayActionExpense,
                Icons.receipt_long_outlined,
                () => showAddExpenseSheet(context),
              ),
              _ActionTile(
                l.todayActionDeposit,
                Icons.savings_outlined,
                () => showAddDepositSheet(context),
              ),
              if (ref.featureOn('guest_meals'))
                _ActionTile(
                  l.todayActionGuest,
                  Icons.person_add_alt,
                  () => addGuest(context, ref, dayKey, members, types),
                ),
              _ActionTile(
                l.todayActionMealOff,
                Icons.no_meals_outlined,
                () => markMealOff(context, ref, dayKey, members, types),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A raised, pressable icon + label tile; labels wrap rather than truncate.
class _ActionTile extends StatelessWidget {
  const _ActionTile(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: PressableScale(
        haptic: true,
        child: AppCard.raised(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs,
            vertical: AppSpace.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpace.xs,
            children: [
              Icon(icon, color: p.ink, size: 22),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
