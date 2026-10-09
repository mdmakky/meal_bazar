import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../push/presentation/push_screens.dart' show SendDueRemindersButton;
import '../../../core/db/db.dart';
import '../../../core/db/sync.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../share_bills/presentation/share_bill_actions.dart';
import '../../mess/presentation/common.dart';
import '../../messages/domain/message_draft.dart';
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';
import '../../report/presentation/report_actions.dart';
import '../application/money_providers.dart';
import '../domain/money.dart';
import 'money_sheets.dart';

enum MoneyTab { members, expense, deposit }

/// হিসাব: this month's figures, then members / expenses / deposits.
/// Bazar has its own tab ([BazarScreen]).
class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key, this.tab});

  /// Opens on this tab (`/money?tab=deposit`), e.g. from Home's attention list.
  final MoneyTab? tab;

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  late var _tab = widget.tab ?? MoneyTab.members;

  @override
  void didUpdateWidget(MoneyScreen old) {
    super.didUpdateWidget(old);
    final tab = widget.tab;
    if (tab != null && tab != old.tab) _tab = tab;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final mess = ref.watch(currentMessProvider);
    final isManager = ref.watch(amIManagerProvider);
    if (messId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.navMoney)),
        body: EmptyView(message: l.moneyNoMess),
      );
    }
    final pdf = ref.featureOn('pdf_report');
    final export = ref.featureOn('export');
    final (addLabel, add) = switch (_tab) {
      MoneyTab.expense => (l.expenseAdd, showAddExpenseSheet),
      MoneyTab.members ||
      MoneyTab.deposit => (l.depositAdd, showAddDepositSheet),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(mess?.name ?? l.navMoney),
        actions: [
          IconButton(
            tooltip: l.monthTitle,
            icon: const Icon(Icons.event_note_outlined),
            onPressed: () => context.push('/money/months'),
          ),
          if (pdf || export)
            PopupMenuButton<String>(
              onSelected: (v) => switch (v) {
                'share' => shareMonthReport(context, messId: messId),
                'print' => printMonthReport(context, messId: messId),
                _ => context.push('/more/export'),
              },
              itemBuilder: (_) => [
                if (pdf) ...[
                  PopupMenuItem(value: 'share', child: Text(l.reportShare)),
                  PopupMenuItem(value: 'print', child: Text(l.reportPrint)),
                ],
                if (export)
                  PopupMenuItem(value: 'export', child: Text(l.exportTitle)),
              ],
            ),
        ],
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(addLabel),
              onPressed: () => add(context),
            )
          : !ref.featureOn('member_deposits')
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l.depositVerifyMine),
              onPressed: () => showMyDepositSheet(context),
            ),
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(currentPeriodProvider(messId));
          ref.invalidate(expensesProvider(messId));
          ref.invalidate(depositsProvider(messId));
          return ref.refresh(monthTotalsProvider(messId).future);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Figures(messId: messId)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.xl,
                  AppSpace.gutter,
                  AppSpace.md,
                ),
                child: InkSegmented<MoneyTab>(
                  segments: [
                    (MoneyTab.members, l.moneyTabMembers),
                    (MoneyTab.expense, l.moneyTabExpense),
                    (MoneyTab.deposit, l.moneyTabDeposit),
                  ],
                  selected: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                ),
              ),
            ),
            switch (_tab) {
              MoneyTab.members => _Balances(messId: messId),
              MoneyTab.expense => _ExpenseList(messId: messId),
              MoneyTab.deposit => _DepositList(messId: messId),
            },
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpace.xxxl * 2),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bazar tab ─────────────────────────────────────────────────────────────

/// বাজার: the month's bazar total (SQL), then every bazar with its sync
/// state; managers add one from the FAB.
class BazarScreen extends ConsumerWidget {
  const BazarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.navBazar)),
        body: EmptyView(message: l.moneyNoMess),
      );
    }
    final bn = banglaDigits(context);
    final text = Theme.of(context).textTheme;
    final total = ref
        .watch(spendingByCategoryProvider(messId))
        .whenData((c) => c.where((x) => x.isBazar).firstOrNull?.total ?? 0);
    return Scaffold(
      appBar: AppBar(title: Text(l.navBazar)),
      floatingActionButton: ref.watch(amIManagerProvider)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l.bazarAdd),
              onPressed: () => showAddBazarSheet(context),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(currentPeriodProvider(messId));
          ref.invalidate(bazarsProvider(messId));
          return ref.refresh(spendingByCategoryProvider(messId).future);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.sm,
                  AppSpace.gutter,
                  AppSpace.xl,
                ),
                child: AppCard.raised(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Row(
                    spacing: AppSpace.lg,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: AppSpace.xs,
                          children: [
                            Text(
                              l.bazarTabTotal,
                              style: AppType.overline(context),
                            ),
                            _Fit(
                              total.value == null
                                  ? Text('…', style: text.displaySmall)
                                  : RollingNumber.money(
                                      total.value!,
                                      banglaDigits: bn,
                                      style: AppType.figure(
                                        text.displaySmall!,
                                        banglaDigits: bn,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const IconTile(Icons.shopping_basket_outlined),
                    ],
                  ),
                ),
              ),
            ),
            _BazarList(messId: messId),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpace.xxxl * 2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scales a figure down instead of clipping it on narrow / large-text screens.
class _Fit extends StatelessWidget {
  const _Fit(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: child,
  );
}

// ── Month figures ─────────────────────────────────────────────────────────

class _Figures extends ConsumerWidget {
  const _Figures({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = banglaDigits(context);
    final text = Theme.of(context).textTheme;
    return ref
        .watch(monthTotalsProvider(messId))
        .when(
          skipLoadingOnRefresh: true,
          loading: () => const LoadingView(rows: 0),
          error: (e, _) => ErrorView(
            message: failureText(context, e),
            onRetry: () => ref.invalidate(monthTotalsProvider(messId)),
          ),
          data: (t) => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.sm,
              AppSpace.gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.md,
              children: [
                // The statement: the month's rate and the sum that proves it.
                AppCard.ink(
                  child: Builder(
                    builder: (context) {
                      final text = Theme.of(context).textTheme;
                      final p = context.palette;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.moneyMealRate,
                            style: AppType.overline(context),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          _Fit(
                            RollingNumber.money(
                              t.mealRate,
                              banglaDigits: bn,
                              style: AppType.figure(
                                text.displayLarge!,
                                banglaDigits: bn,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            t.fixedRate
                                ? l.rateFixed
                                : l.moneyMealRateProof(
                                    money(context, t.foodTotal),
                                    Fmt.meals(t.totalMeals, banglaDigits: bn),
                                  ),
                            style: text.bodyMedium?.copyWith(
                              color: p.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpace.lg),
                          const Divider(),
                          const SizedBox(height: AppSpace.md),
                          Text(
                            l.moneyFoodTotal,
                            style: AppType.overline(context),
                          ),
                          _Fit(
                            RollingNumber.money(
                              t.foodTotal,
                              banglaDigits: bn,
                              style: text.titleLarge,
                            ),
                          ),
                          Text(
                            l.moneyFoodProof,
                            style: text.bodySmall?.copyWith(
                              color: p.inkSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.md,
                  children: [
                    Expanded(
                      child: _Stat(
                        label: l.moneyExtraTotal,
                        value: t.extraTotal,
                        proof: l.moneyExtraProof,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: l.moneyDepositTotal,
                        value: t.creditTotal,
                        proof: l.moneyDepositProof,
                      ),
                    ),
                  ],
                ),
                if (t.unallocatedFood)
                  Text(
                    l.moneyNoMealsWarning,
                    style: text.bodyMedium?.copyWith(
                      color: context.palette.warning,
                    ),
                  ),
                if (rateGapText(l, t, (v) => money(context, v)) case final gap?)
                  Text(gap, style: text.bodyMedium),
              ],
            ),
          ),
        );
  }
}

/// A secondary month figure on a raised card; its proof line under it.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.proof});

  final String label;
  final double value;
  final String proof;

  @override
  Widget build(BuildContext context) {
    final bn = banglaDigits(context);
    final text = Theme.of(context).textTheme;
    return AppCard.raised(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.xs,
        children: [
          Text(
            label,
            style: AppType.overline(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _Fit(
            RollingNumber.money(
              value,
              banglaDigits: bn,
              style: text.titleLarge,
            ),
          ),
          Text(
            proof,
            style: text.bodySmall?.copyWith(color: context.palette.inkTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Shared list plumbing ──────────────────────────────────────────────────

Widget _asyncSliver<T>(
  BuildContext context,
  AsyncValue<T> value, {
  required VoidCallback onRetry,
  required Widget Function(T data) data,
}) => value.when(
  skipLoadingOnRefresh: true,
  loading: () => const SliverToBoxAdapter(child: LoadingView()),
  error: (e, _) => SliverToBoxAdapter(
    child: ErrorView(message: failureText(context, e), onRetry: onRetry),
  ),
  data: data,
);

/// Rows on one raised card (staggered in on first show), then a
/// "load more" button while there is more.
class _PagedSliver<T> extends StatefulWidget {
  const _PagedSliver({
    required this.page,
    required this.empty,
    required this.row,
    required this.loadMore,
  });

  final Paged<T> page;
  final String empty;
  final Widget Function(T item) row;
  final Future<void> Function() loadMore;

  @override
  State<_PagedSliver<T>> createState() => _PagedSliverState<T>();
}

class _PagedSliverState<T> extends State<_PagedSliver<T>> {
  var _loading = false;

  Future<void> _more() async {
    setState(() => _loading = true);
    try {
      await widget.loadMore();
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.page.items;
    if (items.isEmpty) {
      return SliverToBoxAdapter(child: EmptyView(message: widget.empty));
    }
    // ponytail: the card builds every loaded row; a DecoratedSliver if pages
    // ever hold hundreds of rows.
    return SliverToBoxAdapter(
      child: StaggeredList(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              RaisedGroup(
                children: StaggeredList.wrap([
                  for (final i in items) widget.row(i),
                ]),
              ),
              if (widget.page.hasMore)
                AppButton(
                  label: AppLocalizations.of(context).moneyLoadMore,
                  variant: AppButtonVariant.secondary,
                  loading: _loading,
                  onPressed: _more,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A list row: leading anchor, title, subtitle (+ sync status), trailing.
Widget _row(
  BuildContext context, {
  required Widget leading,
  required String title,
  required String subtitle,
  required Widget trailing,
  VoidCallback? onTap,
  Widget? status,
  Widget? titleLead,
}) {
  final text = Theme.of(context).textTheme;
  final p = context.palette;
  return InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.touch + AppSpace.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          spacing: AppSpace.md,
          children: [
            leading,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: AppSpace.sm,
                    children: [
                      ?titleLead,
                      Flexible(
                        child: Text(
                          title,
                          style: text.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(color: p.inkSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ?status,
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    ),
  );
}

/// A day-of-month block ("০২" over "অক্টোবর") leading a dated row.
class _DateBlock extends StatelessWidget {
  const _DateBlock(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = banglaDigits(context);
    final day = shortDate(context, date);
    final month = day.substring(day.indexOf(' ') + 1);
    return ExcludeSemantics(
      child: Container(
        width: 44,
        height: 48,
        decoration: BoxDecoration(
          color: p.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Fmt.digits(date.day.toString().padLeft(2, '0'), bangla: bn),
                style: text.titleMedium?.copyWith(height: 1.1),
              ),
              Text(
                month,
                style: text.labelSmall?.copyWith(color: p.inkSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Amount on top, a small tag under it.
Widget _amountTrailing(BuildContext context, num amount, {String? tag}) {
  final bn = banglaDigits(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    spacing: AppSpace.xs,
    children: [
      Money(
        amount,
        banglaDigits: bn,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      if (tag != null) StatusTag(tag),
    ],
  );
}

Map<String, String> _names(WidgetRef ref, String messId) => {
  for (final m in ref.watch(membersProvider(messId)).value ?? const [])
    m.id: m.displayName,
};

String _paidFrom(AppLocalizations l, Map<String, String> names, String? id) =>
    id == null ? l.moneyPaidFund : names[id] ?? l.moneyPaidPocket;

// ── Balances ──────────────────────────────────────────────────────────────

class _Balances extends ConsumerWidget {
  const _Balances({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = banglaDigits(context);
    final text = Theme.of(context).textTheme;
    final isManager = ref.watch(amIManagerProvider);
    return _asyncSliver(
      context,
      ref.watch(memberBalancesProvider(messId)),
      onRetry: () => ref.invalidate(memberBalancesProvider(messId)),
      data: (list) => list.isEmpty
          ? SliverToBoxAdapter(child: EmptyView(message: l.balanceEmpty))
          : SliverToBoxAdapter(
              child: StaggeredList(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.gutter,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpace.md,
                    children: [
                      if (isManager && ref.featureOn('share_bills'))
                        ShareMessSummaryButton(messId: messId),
                      RaisedGroup(
                        children: StaggeredList.wrap([
                          for (final b in list)
                            _row(
                              context,
                              leading: InitialsAvatar(b.displayName),
                              title: b.displayName,
                              subtitle: l.balanceMeals(
                                Fmt.meals(b.meals, banglaDigits: bn),
                              ),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  RollingNumber.money(
                                    b.closingBalance,
                                    signed: true,
                                    banglaDigits: bn,
                                    style: text.titleSmall,
                                  ),
                                  Text(
                                    balanceWord(l, b.closingBalance),
                                    style: text.labelSmall?.copyWith(
                                      color: context.palette.inkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => showBillSheet(context, messId, b),
                            ),
                        ]),
                      ),
                      if (isManager &&
                          ref.featureOn('push') &&
                          list.any((b) => b.closingBalance < 0))
                        SendDueRemindersButton(messId: messId),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

String balanceWord(AppLocalizations l, double v) => v < 0
    ? l.balanceDue
    : v > 0
    ? l.balanceAdvance
    : l.balanceSettled;

/// "Explain my bill": each SQL figure on its own line, adding up to closing.
Future<void> showBillSheet(
  BuildContext context,
  String messId,
  MemberBalance b,
) {
  final l = AppLocalizations.of(context);
  return AppSheet.show<void>(
    context,
    title: l.balanceExplainTitle(b.displayName),
    child: BillBreakdown(messId: messId, balance: b),
  );
}

/// The bill as a receipt: line items, a dashed rule, the bold total, and
/// the stamp — পরিশোধিত when settled or ahead, বাকি when due.
class BillBreakdown extends ConsumerWidget {
  const BillBreakdown({super.key, required this.messId, required this.balance});

  final String messId;
  final MemberBalance balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = banglaDigits(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final t = ref.watch(monthTotalsProvider(messId)).value;
    final rate = t == null ? '…' : money(context, t.mealRate);
    final meals = Fmt.meals(balance.meals, banglaDigits: bn);
    final due = balance.closingBalance < 0;
    String label(BillPart p) => switch (p) {
      BillPart.opening => l.balanceOpening,
      BillPart.credit => l.balanceCredit,
      BillPart.food =>
        t?.fixedRate ?? false
            ? l.rateBalanceFood(meals, rate)
            : l.balanceFood(meals, rate),
      BillPart.extra => l.balanceExtra,
    };
    Widget line(String name, Widget value, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        spacing: AppSpace.md,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(name, style: style)),
          value,
        ],
      ),
    );
    final receipt = Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final b in billLines(balance))
            line(
              label(b.part),
              Text(
                '${b.amount < 0 ? '−' : '+'} '
                '${money(context, b.amount.abs())}',
                style: text.bodyLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              style: text.bodyMedium?.copyWith(color: p.inkSecondary),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: _DashedRule(),
          ),
          line(
            '${l.balanceClosing} · ${balanceWord(l, balance.closingBalance)}',
            Money(
              balance.closingBalance,
              signed: true,
              banglaDigits: bn,
              style: text.titleLarge,
            ),
            style: text.titleSmall,
          ),
          const SizedBox(height: AppSpace.xl),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            receipt,
            PositionedDirectional(
              end: AppSpace.lg,
              bottom: -AppSpace.sm,
              child: StampMark(due ? l.balanceDue : l.stampPaid, accent: due),
            ),
          ],
        ),
        if (ref.watch(amIManagerProvider) && ref.featureOn('share_bills')) ...[
          const SizedBox(height: AppSpace.xl),
          MemberShareActions(balance: balance),
        ],
      ],
    );
  }
}

/// A receipt's tear line: short hairline dashes.
class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.fromHeight(AppSize.hairline),
    painter: _Dashes(context.palette.borderStrong),
  );
}

class _Dashes extends CustomPainter {
  const _Dashes(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AppSize.hairline;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.color != color;
}

// ── Bazar / expenses / deposits ───────────────────────────────────────────

class _BazarList extends ConsumerWidget {
  const _BazarList({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = banglaDigits(context);
    final names = _names(ref, messId);
    final ops = {
      for (final o in ref.watch(syncQueueProvider).value ?? const <SyncOp>[])
        if (o.entity == 'bazars') o.rowKey: o,
    };
    return _asyncSliver(
      context,
      ref.watch(bazarsProvider(messId)),
      onRetry: () => ref.invalidate(bazarsProvider(messId)),
      data: (page) => _PagedSliver<Bazar>(
        page: page,
        empty: l.bazarEmpty,
        loadMore: ref.read(bazarsProvider(messId).notifier).loadMore,
        row: (b) => _row(
          context,
          leading: _DateBlock(b.date),
          titleLead: BuyerAvatars([for (final id in b.buyers) ?names[id]]),
          title: b.buyerNames(names) ?? l.bazarTitle,
          subtitle: [
            if (b.items.isNotEmpty)
              l.bazarItemCount(Fmt.digits('${b.items.length}', bangla: bn)),
            _paidFrom(l, names, b.paidByMemberId),
          ].join(' · '),
          trailing: _amountTrailing(context, b.amount),
          // Only a pending or failed write says anything.
          status: ops[b.id] == null
              ? null
              : SyncBadge(
                  state: opState(ops[b.id]),
                  onRetry: () => ref.read(syncServiceProvider).retryFailed(),
                  onDiscard: () async {
                    await ref.read(appDbProvider).discard([?ops[b.id]?.id]);
                    ref.invalidate(bazarsProvider(messId));
                  },
                ),
          onTap: () => showBazarDetail(context, b),
        ),
      ),
    );
  }
}

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final names = _names(ref, messId);
    final cats = {
      for (final c
          in ref.watch(expenseCategoriesProvider(messId)).value ?? const [])
        c.id: c.name,
    };
    final isManager = ref.watch(amIManagerProvider);
    final me = ref.watch(currentMembershipProvider)?.member.id;
    final report = ref.featureOn('messages');
    return _asyncSliver(
      context,
      ref.watch(expensesProvider(messId)),
      onRetry: () => ref.invalidate(expensesProvider(messId)),
      data: (page) => _PagedSliver<Expense>(
        page: page,
        empty: l.expenseEmpty,
        loadMore: ref.read(expensesProvider(messId).notifier).loadMore,
        row: (e) => _row(
          context,
          leading: _DateBlock(e.date),
          title: cats[e.categoryId] ?? l.moneyTabExpense,
          subtitle: _paidFrom(l, names, e.paidByMemberId),
          trailing: _amountTrailing(
            context,
            e.amount,
            tag: e.shares.isEmpty ? splitLabel(l, e.split) : l.splitSelected,
          ),
          onTap: isManager
              ? () => showExpenseForm(context, existing: e)
              : report && (e.shares.isEmpty || e.shares.containsKey(me))
              ? () => showEntryDetail(
                  context,
                  title: cats[e.categoryId] ?? l.moneyTabExpense,
                  amount: e.amount,
                  facts: [
                    longDate(context, e.date),
                    _paidFrom(l, names, e.paidByMemberId),
                  ],
                  note: e.note,
                  receiptPath: e.receiptPath,
                  draft: MessageDraft(
                    refType: 'expense',
                    refId: e.id,
                    refLabel: entryLabel(
                      context,
                      cats[e.categoryId] ?? l.moneyTabExpense,
                      e.amount,
                      e.date,
                    ),
                  ),
                )
              : e.receiptPath == null
              ? null
              : () => showReceipt(context, e.receiptPath!),
        ),
      ),
    );
  }
}

class _DepositList extends ConsumerWidget {
  const _DepositList({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final names = _names(ref, messId);
    final isManager = ref.watch(amIManagerProvider);
    return _asyncSliver(
      context,
      ref.watch(depositsProvider(messId)),
      onRetry: () => ref.invalidate(depositsProvider(messId)),
      data: (page) => _PagedSliver<Deposit>(
        // Pending first: they need the manager's attention.
        // ponytail: only reorders loaded rows; a server-side order if pages get long.
        page: (
          items: [
            ...page.items.where((d) => d.status == DepositStatus.pending),
            ...page.items.where((d) => d.status != DepositStatus.pending),
          ],
          hasMore: page.hasMore,
        ),
        empty: l.depositEmpty,
        loadMore: ref.read(depositsProvider(messId).notifier).loadMore,
        row: (d) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _depositRow(context, ref, l, names, isManager, d),
            if (isManager &&
                d.status == DepositStatus.pending &&
                ref.featureOn('deposit_verification'))
              _VerifyActions(deposit: d, name: names[d.memberId] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _depositRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    Map<String, String> names,
    bool isManager,
    Deposit d,
  ) {
    final name = names[d.memberId] ?? l.moneyTabDeposit;
    return _row(
      context,
      leading: InitialsAvatar(name),
      title: name,
      subtitle: [
        shortDate(context, d.date),
        if (d.trxId != null) 'TrxID ${d.trxId}',
        if (d.status == DepositStatus.pending) l.depositPending,
        if (d.status == DepositStatus.rejected) l.depositRejected,
      ].join(' · '),
      trailing: _amountTrailing(
        context,
        d.amount,
        tag: methodLabel(l, d.method, ref.watch(platformConfigProvider)),
      ),
      onTap: isManager
          ? () => showDepositForm(context, existing: d)
          : ref.featureOn('messages') &&
                d.memberId == ref.watch(currentMembershipProvider)?.member.id
          ? () => showEntryDetail(
              context,
              title: l.moneyTabDeposit,
              amount: d.amount,
              facts: [
                longDate(context, d.date),
                methodLabel(l, d.method, ref.read(platformConfigProvider)),
                if (d.trxId != null) 'TrxID ${d.trxId}',
                if (d.status == DepositStatus.pending) l.depositPending,
                if (d.status == DepositStatus.rejected) l.depositRejected,
              ],
              note: d.note,
              receiptPath: d.screenshotPath,
              draft: MessageDraft(
                refType: 'deposit',
                refId: d.id,
                refLabel: entryLabel(
                  context,
                  l.moneyTabDeposit,
                  d.amount,
                  d.date,
                ),
              ),
            )
          : d.screenshotPath == null
          ? null
          : () => showReceipt(context, d.screenshotPath!),
    );
  }
}

/// Verify / reject a member's pending deposit, each behind a confirmation.
class _VerifyActions extends ConsumerStatefulWidget {
  const _VerifyActions({required this.deposit, required this.name});

  final Deposit deposit;
  final String name;

  @override
  ConsumerState<_VerifyActions> createState() => _VerifyActionsState();
}

class _VerifyActionsState extends ConsumerState<_VerifyActions> {
  bool? _busy; // the approve value in flight

  Future<void> _decide(bool approve) async {
    final l = AppLocalizations.of(context);
    final amount = money(context, widget.deposit.amount);
    final ok = await confirmDialog(
      context,
      title: approve ? l.depositVerifyApproveTitle : l.depositVerifyRejectTitle,
      body: approve
          ? l.depositVerifyApproveBody(widget.name, amount)
          : l.depositVerifyRejectBody(widget.name, amount),
      action: approve ? l.depositVerifyApprove : l.depositVerifyReject,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = approve);
    try {
      await ref
          .read(moneyControllerProvider)
          .verifyDeposit(widget.deposit, approve: approve);
      if (mounted) {
        showSnack(
          context,
          approve ? l.depositVerifyDone : l.depositVerifyRejected,
        );
      }
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
          Expanded(
            child: AppButton(
              label: l.depositVerifyReject,
              variant: AppButtonVariant.secondary,
              loading: _busy == false,
              onPressed: _busy == null ? () => _decide(false) : null,
            ),
          ),
          Expanded(
            child: AppButton(
              label: l.depositVerifyApprove,
              loading: _busy == true,
              onPressed: _busy == null ? () => _decide(true) : null,
            ),
          ),
        ],
      ),
    );
  }
}
