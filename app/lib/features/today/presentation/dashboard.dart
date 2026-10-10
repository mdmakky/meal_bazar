import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../audit/application/audit_providers.dart';
import '../../audit/presentation/my_activity_screen.dart';
import '../../meals/presentation/meal_widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart' show SectionTitle, StatusTag;
import '../../messages/application/unread_provider.dart';
import '../../money/presentation/money_screen.dart';
import '../../money/presentation/money_sheets.dart';
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';
import '../../push/presentation/push_screens.dart' show SendDueRemindersButton;

/// The month below Home's statement card. Every money figure is a SQL figure;
/// each section loads and fails alone.
///
/// Manager: what needs me, the mess fund, who owes, spending, the rate trend.
/// Member: everyone's account (transparency), entries about me, spending,
/// the rate trend.
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
    final charts = ref.featureOn('dashboard_charts');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (manager) ...[
          AttentionCard(messId: messId),
          SectionTitle(l.dashTitle),
          _CashCard(messId: messId),
          SectionTitle(l.dashWhoOwes),
          _DuesList(messId: messId),
        ] else ...[
          // Members see the mess fund too (hidden when the mess keeps none).
          SectionTitle(l.dashTitle),
          _CashCard(messId: messId),
          SectionTitle(l.transTitle),
          _Transparency(messId: messId),
          SectionTitle(l.activityTitle),
          _MyActivity(messId: messId),
        ],
        if (charts) ...[
          SectionTitle(l.dashCategoryTitle),
          CategoryBars(messId: messId),
          MonthlyRateChart(messId: messId),
        ],
      ],
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

String _count(int n, bool bn) => Fmt.digits('$n', bangla: bn);

/// Rows in one raised card, hairlines between, staggered in on first build.
/// [footer] sits under the rows, past a hairline.
class _ListCard extends StatelessWidget {
  const _ListCard(this.rows, {this.footer});

  final List<Widget> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    Widget ruled(Widget r) => DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.palette.border)),
      ),
      child: r,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: AppCard.raised(
        padding: EdgeInsets.zero,
        child: StaggeredList(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...StaggeredList.wrap([
                for (final (i, r) in rows.indexed) i == 0 ? r : ruled(r),
              ]),
              if (footer != null) ruled(footer),
            ],
          ),
        ),
      ),
    );
  }
}

/// A member's first letter (Bangla grapheme intact) on an ink circle.
class Initial extends StatelessWidget {
  const Initial(this.name, {super.key, this.radius = 20});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final first = name.trim().characters.firstOrNull ?? '?';
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: p.ink,
        child: Text(
          first.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: p.onInk, height: 1),
        ),
      ),
    );
  }
}

// ── Manager ───────────────────────────────────────────────────────────────

/// "What needs me today": only the rows with something to do, each opening
/// the screen that does it. Nothing at all when everything is done.
class AttentionCard extends ConsumerWidget {
  const AttentionCard({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final unread = ref.watch(unreadMessagesCountProvider(messId)).value ?? 0;
    final deposits = ref.featureOn('member_deposits');
    final recurring = ref.featureOn('recurring');
    final value = ref.watch(attentionProvider(messId));
    // Calm while loading: the card appears when there is something to say.
    if (value.hasError && !value.hasValue) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.md),
        child: ErrorView(
          message: failureText(context, value.error!),
          onRetry: () => ref.invalidate(attentionProvider(messId)),
        ),
      );
    }
    final a = value.value;
    final rows = <(IconData, String, VoidCallback)>[
      if (a != null && deposits && a.pendingDeposits > 0)
        (
          Icons.verified_outlined,
          l.attnDeposits(_count(a.pendingDeposits, bn)),
          () => context.go('/money?tab=${MoneyTab.deposit.name}'),
        ),
      if (a != null && a.pendingBazarRequests > 0)
        (
          Icons.shopping_basket_outlined,
          l.bazarReqAttn(_count(a.pendingBazarRequests, bn)),
          () => context.go('/bazar'),
        ),
      if (a != null && a.pendingMembers > 0)
        (
          Icons.person_add_alt_outlined,
          l.attnJoin(_count(a.pendingMembers, bn)),
          () => context.push('/more/members'),
        ),
      if (unread > 0)
        (
          Icons.forum_outlined,
          l.attnMessages(_count(unread, bn)),
          () => context.push('/more/messages'),
        ),
      if (a != null && a.mealsMissing > 0)
        (
          Icons.restaurant_outlined,
          l.attnMeals(_count(a.mealsMissing, bn)),
          () => context.go('/meals'),
        ),
      if (a != null && recurring && a.pendingRecurring > 0)
        (
          Icons.event_repeat,
          l.recurringPending(_count(a.pendingRecurring, bn)),
          () => context.push('/more/recurring'),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.attnTitle),
        _ListCard([
          for (final (icon, label, onTap) in rows)
            ListTile(
              minTileHeight: AppSize.touch + AppSpace.sm,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
              ),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: p.surfaceMuted,
                child: Icon(icon, size: 20, color: p.ink),
              ),
              title: Text(label, style: text.titleSmall),
              trailing: Icon(Icons.chevron_right, color: p.inkTertiary),
              onTap: onTap,
            ),
        ]),
      ],
    );
  }
}

/// Cash in the mess fund this month, with its proof.
class _CashCard extends ConsumerWidget {
  const _CashCard({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    if (ref.watch(currentMessProvider)?.fundMode == false) {
      return const SizedBox.shrink();
    }
    final manager = ref.watch(amIManagerProvider);
    return _section(
      context,
      ref.watch(messCashProvider(messId)),
      onRetry: () => ref.invalidate(messCashProvider(messId)),
      data: (c) {
        if (c == null) return const SizedBox.shrink();
        String m(num v) => money(context, v);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: AppCard.raised(
            onTap: () => context.go('/money?tab=${MoneyTab.deposit.name}'),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.xs,
                children: [
                  Text(l.cashTitle, style: AppType.overline(context)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: RollingNumber.money(
                      c.cash,
                      banglaDigits: bn,
                      color: c.cash < 0 ? p.due : null,
                      style: text.displaySmall,
                    ),
                  ),
                  Text(
                    l.cashProof(m(c.depositsIn), m(c.fundSpent)),
                    style: text.bodyMedium?.copyWith(
                      color: p.inkSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (c.cash < 0)
                    Container(
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: p.due.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpace.sm,
                        children: [
                          Row(
                            spacing: AppSpace.sm,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: p.due),
                              Expanded(
                                child: Text(
                                  l.fundModeShortTitle(m(-c.cash)),
                                  key: const Key('cash-short'),
                                  style: text.titleSmall?.copyWith(
                                    color: p.due,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            manager
                                ? l.splitMemNegativeCash
                                : l.fundShortMemberNote,
                            key: const Key('cash-negative-note'),
                            style: text.bodySmall?.copyWith(
                              color: p.inkSecondary,
                            ),
                          ),
                          if (manager)
                            AppButton(
                              key: const Key('cash-fix'),
                              label: l.fundModeFix,
                              variant: AppButtonVariant.secondary,
                              onPressed: () => context.go(
                                '/money?tab=${MoneyTab.expense.name}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (c.pendingDeposits > 0)
                    Text(
                      l.cashPending(m(c.pendingDeposits)),
                      style: text.bodySmall?.copyWith(color: p.inkTertiary),
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

/// Biggest dues first, five at most; the full list lives on হিসাব.
class _DuesList extends ConsumerWidget {
  const _DuesList({required this.messId});

  static const _top = 5;

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final text = Theme.of(context).textTheme;
    final push = ref.featureOn('push');
    return _section(
      context,
      ref.watch(memberBalancesProvider(messId)),
      onRetry: () => ref.invalidate(memberBalancesProvider(messId)),
      data: (list) {
        if (list.isEmpty) return _Quiet(l.balanceEmpty);
        final sorted = [...list]
          ..sort((a, b) => a.closingBalance.compareTo(b.closingBalance));
        final owes = sorted.any((b) => b.closingBalance < 0);
        return _ListCard(
          [
            for (final b in sorted.take(_top))
              ListTile(
                key: ValueKey('due-${b.memberId}'),
                minTileHeight: AppSize.touch + AppSpace.xs,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                ),
                leading: Initial(b.displayName, radius: 16),
                title: Text(
                  b.displayName,
                  style: text.titleSmall,
                  overflow: TextOverflow.ellipsis,
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
          ],
          footer: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                if (!owes) _Quiet(l.dashAllSettled),
                if (owes && push) SendDueRemindersButton(messId: messId),
                AppButton(
                  label: l.dashSeeAll,
                  variant: AppButtonVariant.text,
                  onPressed: () => context.go('/money'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Member ────────────────────────────────────────────────────────────────

/// Everyone's month, read-only: deposits, own-pocket payments, balance.
/// Dues first, then advances; my row is marked; a member who left shows only
/// while the month has something of theirs, tagged চলে গেছেন.
class _Transparency extends ConsumerWidget {
  const _Transparency({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final small = text.bodySmall?.copyWith(
      color: p.inkSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final left = ref.watch(leftMemberIdsProvider(messId));
    final me = ref.watch(currentMembershipProvider)?.member.id;
    return _section(
      context,
      ref.watch(transparencyProvider(messId)),
      onRetry: () => ref.invalidate(transparencyProvider(messId)),
      data: (all) {
        final rows = [
          for (final r in all)
            if (shownInPeriod(
              left: left.contains(r.memberId),
              figures: [r.deposits, r.ownPocket, r.closingBalance],
            ))
              r,
        ]..sort((a, b) => duesFirst(a.closingBalance, b.closingBalance));
        if (rows.isEmpty) return _Quiet(l.balanceEmpty);
        String m(num v) => money(context, v);
        return _ListCard(
          [
            for (final r in rows)
              MergeSemantics(
                key: ValueKey('trans-${r.memberId}'),
                child: Container(
                  color: r.memberId == me ? p.surfaceMuted : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.md,
                  ),
                  child: Row(
                    spacing: AppSpace.md,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Row(
                              spacing: AppSpace.sm,
                              children: [
                                Flexible(
                                  child: Text(
                                    r.displayName,
                                    style: text.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (r.memberId == me)
                                  Flexible(
                                    child: StatusTag(l.youTag, strong: true),
                                  )
                                else if (left.contains(r.memberId))
                                  Flexible(child: StatusTag(l.membersLeft)),
                              ],
                            ),
                            Text(
                              [
                                '${l.transDeposits} ${m(r.deposits)}',
                                if (r.ownPocket > 0)
                                  '${l.transOwnPocket} ${m(r.ownPocket)}',
                              ].join(' · '),
                              style: small,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Money(
                            r.closingBalance,
                            signed: true,
                            banglaDigits: bn,
                            style: text.titleSmall,
                          ),
                          Text(
                            balanceWord(l, r.closingBalance),
                            style: text.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
          footer: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            child: Text(
              l.transNote,
              style: text.bodySmall?.copyWith(color: p.inkTertiary),
            ),
          ),
        );
      },
    );
  }
}

/// What others recorded about me, newest first, edit bursts folded; the
/// latest five, then the way to all of them.
class _MyActivity extends ConsumerWidget {
  const _MyActivity({required this.messId});

  static const _top = 5;

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final names = ref.watch(auditNamesProvider(messId));
    return _section(
      context,
      ref.watch(myActivityProvider(messId)),
      onRetry: () => ref.invalidate(myActivityProvider(messId)),
      data: (items) => items.isEmpty
          ? _Quiet(l.activityEmpty)
          : _ListCard(
              [
                for (final e in items.take(_top))
                  ActivityRow(
                    key: ValueKey('act-${e.id}'),
                    entry: e,
                    names: names,
                  ),
              ],
              footer: items.length <= _top
                  ? null
                  : Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.xs),
                        child: AppButton(
                          label: l.activitySeeAll,
                          variant: AppButtonVariant.text,
                          onPressed: () => context.push('/more/activity'),
                        ),
                      ),
                    ),
            ),
    );
  }
}

// ── Charts (monochrome; today is the only turmeric) ───────────────────────

const _chartHeight = 160.0;

Widget _axisText(BuildContext context, String s) => Text(
  s,
  maxLines: 1,
  style: Theme.of(context).textTheme.labelSmall?.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
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

/// Spending by category: the four largest (SQL order) and the rest as one.
class CategoryBars extends ConsumerWidget {
  const CategoryBars({super.key, required this.messId});

  static const _top = 4;

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
      data: (all) {
        if (all.isEmpty) return _Quiet(l.dashChartEmpty);
        final rest = all.skip(_top);
        final rows = [
          for (final r in all.take(_top))
            (r.isBazar ? l.bazarTitle : r.category, r.total),
          // Display-only sum of the SQL category totals.
          if (rest.isNotEmpty)
            (l.dashOthers, rest.fold(0.0, (s, r) => s + r.total)),
        ];
        final max = rows.map((r) => r.$2).reduce(math.max);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: AppCard.raised(
            child: _growIn(
              (grow) => Column(
                spacing: AppSpace.md,
                children: [
                  for (final (name, total) in rows)
                    MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpace.xs,
                        children: [
                          Row(
                            spacing: AppSpace.sm,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodyMedium?.copyWith(
                                    color: p.ink,
                                  ),
                                ),
                              ),
                              Money(
                                total,
                                banglaDigits: bn,
                                style: text.bodyMedium,
                              ),
                            ],
                          ),
                          ExcludeSemantics(
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: max == 0 ? 0 : grow * total / max,
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

/// The billing periods that have data, from the mess's first one with any
/// spending: earlier empty months are not zeros, they did not exist.
List<MonthPoint> activeMonths(List<MonthPoint> points) =>
    points.skipWhile((x) => x.foodTotal == 0 && x.extraTotal == 0).toList();

/// Short month label: "Oct" in English, the Bangla month name in Bangla.
String shortMonth(DateTime d, String locale) {
  final name = Fmt.dateLong(d, locale: locale).split(' ')[1];
  return locale == 'en' && name.length > 3 ? name.substring(0, 3) : name;
}

/// Meal rate over the recent billing periods that have data, with its
/// own title. Hidden until there are two such periods to compare.
class MonthlyRateChart extends ConsumerWidget {
  const MonthlyRateChart({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final bn = bnDigits(context);
    final locale = Localizations.localeOf(context).languageCode;
    String month(DateTime d) => shortMonth(d, locale);
    final history = ref.watch(monthHistoryProvider(messId));
    // A trend is extra: loading and failure stay quiet, a pull refreshes it.
    final points = activeMonths(history.value ?? const []);
    if (points.length < 2) return const SizedBox.shrink();
    final summary =
        '${l.dashMonthlyTitle}: '
        '${points.map((x) => '${month(x.start)} ${money(context, x.mealRate)}').join(', ')}';
    final top = points.map((x) => x.mealRate).reduce(math.max);
    final last = points.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.dashMonthlyTitle),
        Semantics(
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
              child: SizedBox(
                height: _chartHeight,
                child: _growIn(
                  (grow) => LineChart(
                    duration: Duration.zero,
                    LineChartData(
                      // Half a slot of air each side: edge labels never clip.
                      minX: -0.5,
                      maxX: last + 0.5,
                      minY: 0,
                      maxY: top == 0 ? 1 : top * 1.2,
                      lineTouchData: const LineTouchData(enabled: false),
                      borderData: FlBorderData(show: false),
                      gridData: _grid(context),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (v, meta) =>
                                v == meta.max || v == meta.min && v != 0
                                ? const SizedBox.shrink()
                                : SideTitleWidget(
                                    meta: meta,
                                    child: _axisText(
                                      context,
                                      Fmt.digits(
                                        meta.formattedValue,
                                        bangla: bn,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (v, meta) {
                              final i = v.round();
                              if (v != i || i < 0 || i > last) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                fitInside: SideTitleFitInsideData.fromTitleMeta(
                                  meta,
                                ),
                                child: _axisText(
                                  context,
                                  month(points[i].start),
                                ),
                              );
                            },
                          ),
                        ),
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
                              radius: i == last ? 4 : 3,
                              color: i == last ? p.accent : p.ink,
                              strokeWidth: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
