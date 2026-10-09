import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../meals/presentation/meal_grid.dart';
import '../../meals/presentation/meal_widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../money/application/money_providers.dart';
import '../../money/domain/money.dart' show rateGapText;
import '../../money/presentation/money_screen.dart';
import '../../money/presentation/money_sheets.dart';
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';

/// "এই মাস": the month at a glance on হোম (Plan §16–17).
/// Every money figure is a SQL figure; each section loads and fails alone.
class MonthDashboard extends ConsumerWidget {
  const MonthDashboard({
    super.key,
    required this.messId,
    required this.manager,
  });

  final String messId;
  final bool manager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(l.dashTitle, large: true),
        if (manager) ...[
          _ManagerStats(messId: messId),
          _Title(l.dashWhoOwes),
          _DuesList(messId: messId),
        ] else
          _MyAccount(messId: messId),
        if (ref.featureOn('dashboard_charts')) ...[
          _Title(l.dashDailyTitle),
          DailyMealsChart(messId: messId),
          _Title(l.dashCategoryTitle),
          CategoryBars(messId: messId),
          _Title(l.dashMonthlyTitle),
          MonthlyRateChart(messId: messId),
        ],
        if (!manager) ...[
          _Title(l.dashRecentBazar),
          _RecentBazar(messId: messId),
        ],
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.large = false});

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter,
        large ? AppSpace.xxl : AppSpace.xl,
        AppSpace.gutter,
        AppSpace.md,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: large ? t.headlineSmall : t.titleLarge),
      ),
    );
  }
}

/// Loading / error (+retry) / data for one section.
Widget _section<T>(
  BuildContext context,
  AsyncValue<T> value, {
  required VoidCallback onRetry,
  required Widget Function(T data) data,
}) => value.when(
  skipLoadingOnRefresh: true,
  loading: () => const LoadingView(rows: 1),
  error: (e, _) =>
      ErrorView(message: failureText(context, e), onRetry: onRetry),
  data: data,
);

class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}

/// Stat cards two per row; a row's cards share their height.
class _StatGrid extends StatelessWidget {
  const _StatGrid(this.stats);

  final List<Widget> stats;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
    child: Column(
      spacing: AppSpace.sm,
      children: [
        for (var i = 0; i < stats.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.sm,
              children: [
                Expanded(child: stats[i]),
                Expanded(
                  child: i + 1 < stats.length
                      ? stats[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// A raised stat card: overline label, the (rolling) value, its proof.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.proof,
  });

  final String label;
  final Widget value;
  final String? proof;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final proof = this.proof;
    return AppCard.raised(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.md,
        AppSpace.md,
      ),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.xs,
          children: [
            Text(label, style: AppType.overline(context)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: value,
            ),
            if (proof != null)
              Text(
                proof,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: p.inkTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A stat's value: rolling money or count, '…' while a part still loads.
Widget _value(
  BuildContext context,
  num? v, {
  bool isMoney = true,
  Color? color,
  bool signed = false,
  TextStyle? style,
}) {
  final s = style ?? Theme.of(context).textTheme.headlineSmall;
  final bn = bnDigits(context);
  if (v == null) return Text('…', style: s);
  return isMoney
      ? RollingNumber.money(
          v,
          banglaDigits: bn,
          signed: signed,
          color: color,
          style: s,
        )
      : RollingNumber(v, banglaDigits: bn, color: color, style: s);
}

String _count(int n, bool bn) => Fmt.digits('$n', bangla: bn);

// ── Manager ───────────────────────────────────────────────────────────────

class _ManagerStats extends ConsumerWidget {
  const _ManagerStats({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final bn = bnDigits(context);
    final totals = ref.watch(monthTotalsProvider(messId));
    final balances = ref.watch(memberBalancesProvider(messId));
    final members = ref.watch(membersProvider(messId)).value ?? const [];
    final period = ref.watch(currentPeriodProvider(messId)).value;
    final bazar = ref
        .watch(spendingByCategoryProvider(messId))
        .whenData((c) => c.where((x) => x.isBazar).firstOrNull?.total ?? 0)
        .value;
    return _section(
      context,
      // Both are needed: totals for the month, balances for dues/advances.
      totals.whenData((t) => (t, balances.value)),
      onRetry: () {
        ref.invalidate(monthTotalsProvider(messId));
        ref.invalidate(memberBalancesProvider(messId));
      },
      data: (data) {
        final (t, list) = data;
        String m(num v) => money(context, v);
        final active = members
            .where((x) => x.status == MemberStatus.active)
            .length;
        final pending = members
            .where((x) => x.status == MemberStatus.pending)
            .length;
        // Display-only sums of per-member SQL closing balances.
        final dues = [...?list?.where((b) => b.closingBalance < 0)];
        final advances = [...?list?.where((b) => b.closingBalance > 0)];
        double sum(List<MemberBalance> xs) =>
            xs.fold(0.0, (s, b) => s + b.closingBalance);
        return _StatGrid([
          StatTile(
            label: l.dashMembers,
            value: _value(context, active, isMoney: false),
            proof: pending > 0
                ? l.dashMembersPending(_count(pending, bn))
                : l.dashMembersProof,
          ),
          StatTile(
            label: l.dashRate,
            value: _value(context, t.mealRate),
            proof: t.fixedRate
                ? [l.rateFixed, ?rateGapText(l, t, m)].join(' · ')
                : l.moneyMealRateProof(
                    m(t.foodTotal),
                    decimal(t.totalMeals, bangla: bn),
                  ),
          ),
          StatTile(
            label: l.dashBazar,
            value: _value(context, bazar),
            proof: l.dashBazarProof(m(t.foodTotal)),
          ),
          StatTile(
            label: l.dashExtra,
            value: _value(context, t.extraTotal),
            proof: l.dashExtraProof(m(t.foodTotal + t.extraTotal)),
          ),
          StatTile(
            label: l.dashDeposits,
            value: _value(context, t.creditTotal),
            proof: l.moneyDepositProof,
          ),
          StatTile(
            label: l.dashMeals,
            value: _value(context, t.totalMeals, isMoney: false),
            proof: period == null
                ? null
                : l.dashPeriod(
                    shortDate(context, period.start),
                    shortDate(
                      context,
                      period.end.subtract(const Duration(hours: 12)),
                    ),
                  ),
          ),
          StatTile(
            label: l.dashDues,
            value: _value(
              context,
              list == null ? null : -sum(dues),
              color: dues.isEmpty ? null : p.due,
            ),
            proof: list == null
                ? null
                : l.dashDuesProof(_count(dues.length, bn)),
          ),
          StatTile(
            label: l.dashAdvances,
            value: _value(
              context,
              list == null ? null : sum(advances),
              color: advances.isEmpty ? null : p.advance,
            ),
            proof: list == null
                ? null
                : l.dashAdvancesProof(_count(advances.length, bn)),
          ),
        ]);
      },
    );
  }
}

/// Members by closing balance, biggest due first; tap explains the bill.
class _DuesList extends ConsumerWidget {
  const _DuesList({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final text = Theme.of(context).textTheme;
    return _section(
      context,
      ref.watch(memberBalancesProvider(messId)),
      onRetry: () => ref.invalidate(memberBalancesProvider(messId)),
      data: (list) {
        if (list.isEmpty) return _Quiet(l.balanceEmpty);
        final sorted = [...list]
          ..sort((a, b) => a.closingBalance.compareTo(b.closingBalance));
        return _ListCard([
          for (final b in sorted)
            ListTile(
              key: ValueKey('due-${b.memberId}'),
              minTileHeight: AppSize.touch + AppSpace.sm,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
              ),
              leading: Initial(b.displayName),
              title: Text(b.displayName, style: text.titleSmall),
              subtitle: Text(
                l.balanceMeals(Fmt.meals(b.meals, banglaDigits: bn)),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Money(
                    b.closingBalance,
                    signed: true,
                    banglaDigits: bn,
                    style: text.titleSmall,
                  ),
                  Text(
                    balanceWord(l, b.closingBalance),
                    style: text.labelSmall,
                  ),
                ],
              ),
              onTap: () => showBillSheet(context, messId, b),
            ),
        ]);
      },
    );
  }
}

/// Rows in one raised card, hairlines between, staggered in on first build.
class _ListCard extends StatelessWidget {
  const _ListCard(this.rows);

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
    child: AppCard.raised(
      padding: EdgeInsets.zero,
      child: StaggeredList(
        child: Column(
          children: StaggeredList.wrap([
            for (final (i, r) in rows.indexed)
              i == 0
                  ? r
                  : DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: context.palette.border),
                        ),
                      ),
                      child: r,
                    ),
          ]),
        ),
      ),
    ),
  );
}

/// A member's first letter (Bangla grapheme intact) on an ink circle.
class Initial extends StatelessWidget {
  const Initial(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final first = name.trim().characters.firstOrNull ?? '?';
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: 20,
        backgroundColor: p.ink,
        child: Text(
          first.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: p.onInk, height: 1),
        ),
      ),
    );
  }
}

// ── Member ────────────────────────────────────────────────────────────────

class _MyAccount extends ConsumerWidget {
  const _MyAccount({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final myId = ref.watch(currentMembershipProvider)?.member.id;
    final rate = ref.watch(monthTotalsProvider(messId)).value?.mealRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(l.dashMine),
        _section(
          context,
          ref.watch(memberBalancesProvider(messId)),
          onRetry: () => ref.invalidate(memberBalancesProvider(messId)),
          data: (list) {
            final b = list.where((x) => x.memberId == myId).firstOrNull;
            if (b == null) return _Quiet(l.dashNotInMonth);
            String m(num v) => money(context, v);
            final c = b.closingBalance;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.md,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.gutter,
                  ),
                  child: StatTile(
                    label: l.balanceClosing,
                    value: _value(
                      context,
                      c,
                      signed: true,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    proof: balanceWord(l, c),
                  ),
                ),
                _StatGrid([
                  StatTile(
                    label: l.dashMyMeals,
                    value: _value(context, b.meals, isMoney: false),
                  ),
                  StatTile(
                    label: l.dashMyFood,
                    value: _value(context, b.foodCost),
                    proof: l.dashMyFoodProof(
                      Fmt.meals(b.meals, banglaDigits: bn),
                      rate == null ? '…' : m(rate),
                    ),
                  ),
                  StatTile(
                    label: l.dashExtra,
                    value: _value(context, b.extraCost),
                    proof: l.moneyExtraProof,
                  ),
                  StatTile(
                    label: l.dashMyPaid,
                    value: _value(context, b.credit),
                    proof: l.balanceCredit,
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.gutter,
                  ),
                  child: AppButton(
                    label: l.dashExplain,
                    icon: Icons.receipt_long_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => showBillSheet(context, messId, b),
                  ),
                ),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.sm,
            AppSpace.gutter,
            0,
          ),
          child: Row(
            spacing: AppSpace.sm,
            children: [
              if (ref.featureOn('member_meal_off'))
                Expanded(
                  child: AppButton(
                    label: l.mealOffTomorrow,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => offTomorrow(context, ref),
                  ),
                ),
              if (ref.featureOn('member_deposits'))
                Expanded(
                  child: AppButton(
                    label: l.depositVerifyMine,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => showMyDepositSheet(context),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentBazar extends ConsumerWidget {
  const _RecentBazar({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final names = <String, String>{
      for (final m in ref.watch(membersProvider(messId)).value ?? const [])
        m.id: m.displayName,
    };
    return _section(
      context,
      ref.watch(bazarsProvider(messId)),
      onRetry: () => ref.invalidate(bazarsProvider(messId)),
      data: (page) => page.items.isEmpty
          ? _Quiet(l.bazarEmpty)
          : _ListCard([
              for (final b in page.items.take(5))
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                  ),
                  title: Text(b.buyerNames(names) ?? l.bazarTitle),
                  subtitle: Text(shortDate(context, b.date)),
                  trailing: Money(b.amount, banglaDigits: bn),
                  onTap: () => showBazarDetail(context, b),
                ),
            ]),
    );
  }
}

// ── Charts (monochrome; today is the only turmeric) ───────────────────────

const _chartHeight = 160.0;

Widget _axisText(BuildContext context, String s) => Text(
  s,
  style: Theme.of(context).textTheme.labelSmall?.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  ),
);

FlTitlesData _titles({
  required Widget Function(double v, TitleMeta meta) left,
  required Widget Function(double v, TitleMeta meta) bottom,
  double leftReserved = 32,
  double? bottomInterval,
}) => FlTitlesData(
  topTitles: const AxisTitles(),
  rightTitles: const AxisTitles(),
  leftTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: leftReserved,
      getTitlesWidget: left,
    ),
  ),
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 24,
      interval: bottomInterval,
      getTitlesWidget: bottom,
    ),
  ),
);

FlGridData _grid(BuildContext context) => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => FlLine(
    color: context.palette.border,
    strokeWidth: 1,
    dashArray: const [2, 4],
  ),
);

/// A chart in a raised card, labelled by its summary for screen readers.
Widget _chartBox(String summary, Widget chart) => Semantics(
  container: true,
  label: summary,
  excludeSemantics: true,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
    child: AppCard.raised(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xs,
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: SizedBox(height: _chartHeight, child: chart),
    ),
  ),
);

/// Grows its marks in once (0 → 1) on first build; instant with reduced
/// motion. Later data changes just redraw.
Widget _growIn(Widget Function(double t) chart) => Builder(
  builder: (context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.of(context, AppMotion.slow * 2),
    curve: AppMotion.arrive,
    builder: (context, t, _) => RepaintBoundary(child: chart(t)),
  ),
);

/// Billable meals per day this month; today's bar in turmeric.
class DailyMealsChart extends ConsumerWidget {
  const DailyMealsChart({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final bn = bnDigits(context);
    final now = today();
    return _section(
      context,
      ref.watch(dailyMealsProvider(messId)),
      onRetry: () => ref.invalidate(dailyMealsProvider(messId)),
      data: (days) {
        if (days.every((d) => d.meals == 0)) return _Quiet(l.dashChartEmpty);
        final top = days.reduce((a, b) => b.meals > a.meals ? b : a);
        final total = days.fold(0.0, (s, d) => s + d.meals);
        final summary = l.dashDailySummary(
          Fmt.meals(total, banglaDigits: bn),
          Fmt.meals(top.meals, banglaDigits: bn),
          shortDate(context, top.date),
        );
        return _chartBox(
          summary,
          _growIn(
            (grow) => BarChart(
              duration: Duration.zero,
              BarChartData(
                maxY: top.meals * 1.15,
                minY: 0,
                alignment: BarChartAlignment.spaceBetween,
                barTouchData: const BarTouchData(enabled: false),
                borderData: FlBorderData(show: false),
                gridData: _grid(context),
                titlesData: _titles(
                  left: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: _axisText(
                      context,
                      Fmt.digits(meta.formattedValue, bangla: bn),
                    ),
                  ),
                  bottom: (v, meta) {
                    final d = days[v.toInt()].date;
                    // Week starts and today: enough to orient, no clutter.
                    final show = v.toInt() % 7 == 0 || d == now;
                    return SideTitleWidget(
                      meta: meta,
                      child: show
                          ? _axisText(
                              context,
                              Fmt.digits('${d.day}', bangla: bn),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
                barGroups: [
                  for (final (i, d) in days.indexed)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: d.meals * grow,
                          width: 6,
                          color: d.date == now
                              ? p.accent
                              : p.ink.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Spending by category as horizontal bars, largest first (SQL order).
class CategoryBars extends ConsumerWidget {
  const CategoryBars({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = bnDigits(context);
    return _section(
      context,
      ref.watch(spendingByCategoryProvider(messId)),
      onRetry: () => ref.invalidate(spendingByCategoryProvider(messId)),
      data: (rows) {
        if (rows.isEmpty) return _Quiet(l.dashChartEmpty);
        final max = rows.map((r) => r.total).reduce(math.max);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: AppCard.raised(
            child: _growIn(
              (grow) => Column(
                spacing: AppSpace.md,
                children: [
                  for (final r in rows)
                    MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpace.xs,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.isBazar ? l.bazarTitle : r.category,
                                  style: text.bodyMedium?.copyWith(
                                    color: p.ink,
                                  ),
                                ),
                              ),
                              Money(
                                r.total,
                                banglaDigits: bn,
                                style: text.bodyMedium,
                              ),
                            ],
                          ),
                          ExcludeSemantics(
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: max == 0 ? 0 : grow * r.total / max,
                              child: Container(
                                height: AppSpace.sm,
                                decoration: BoxDecoration(
                                  color: p.ink.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(
                                    AppSpace.xs,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Meal rate over the last six billing periods.
class MonthlyRateChart extends ConsumerWidget {
  const MonthlyRateChart({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final bn = bnDigits(context);
    final locale = Localizations.localeOf(context).languageCode;
    String month(DateTime d) => Fmt.dateLong(d, locale: locale).split(' ')[1];
    return _section(
      context,
      ref.watch(monthHistoryProvider(messId)),
      onRetry: () => ref.invalidate(monthHistoryProvider(messId)),
      data: (points) {
        if (points.every((x) => x.mealRate == 0)) {
          return _Quiet(l.dashChartEmpty);
        }
        final summary =
            '${l.dashMonthlyTitle}: '
            '${points.map((x) => '${month(x.start)} ${money(context, x.mealRate)}').join(', ')}';
        final top = points.map((x) => x.mealRate).reduce(math.max);
        return _chartBox(
          summary,
          _growIn(
            (grow) => LineChart(
              duration: Duration.zero,
              LineChartData(
                minY: 0,
                maxY: top * 1.2,
                lineTouchData: const LineTouchData(enabled: false),
                borderData: FlBorderData(show: false),
                gridData: _grid(context),
                titlesData: _titles(
                  leftReserved: 40,
                  bottomInterval: 1,
                  left: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: _axisText(
                      context,
                      Fmt.digits(meta.formattedValue, bangla: bn),
                    ),
                  ),
                  bottom: (v, meta) {
                    final i = v.toInt();
                    return SideTitleWidget(
                      meta: meta,
                      child: v == i && i >= 0 && i < points.length
                          ? SizedBox(
                              width: AppSpace.xxxl,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _axisText(
                                  context,
                                  month(points[i].start),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final (i, x) in points.indexed)
                        FlSpot(i.toDouble(), x.mealRate * grow),
                    ],
                    color: p.ink,
                    barWidth: 2,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    dotData: FlDotData(
                      // The current period is live: its dot is turmeric.
                      getDotPainter: (_, _, _, i) => FlDotCirclePainter(
                        radius: i == points.length - 1 ? 4 : 3,
                        color: i == points.length - 1 ? p.accent : p.ink,
                        strokeWidth: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
