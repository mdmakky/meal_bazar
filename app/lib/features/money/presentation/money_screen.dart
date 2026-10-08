import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/db.dart';
import '../../../core/db/sync.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart';
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
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  var _tab = MoneyTab.members;

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
          PopupMenuButton<bool>(
            onSelected: (share) => share
                ? shareMonthReport(context, messId: messId)
                : printMonthReport(context, messId: messId),
            itemBuilder: (_) => [
              PopupMenuItem(value: true, child: Text(l.reportShare)),
              PopupMenuItem(value: false, child: Text(l.reportPrint)),
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
                child: SegmentedButton<MoneyTab>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: MoneyTab.members,
                      label: Text(l.moneyTabMembers),
                    ),
                    ButtonSegment(
                      value: MoneyTab.expense,
                      label: Text(l.moneyTabExpense),
                    ),
                    ButtonSegment(
                      value: MoneyTab.deposit,
                      label: Text(l.moneyTabDeposit),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
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
                  AppSpace.lg,
                ),
                child: Figure(
                  label: l.bazarTabTotal,
                  value: total.value == null
                      ? '…'
                      : money(context, total.value!),
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

// ── Month figures ─────────────────────────────────────────────────────────

class _Figures extends ConsumerWidget {
  const _Figures({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = banglaDigits(context);
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.sm,
              children: [
                _pair(
                  Figure(
                    label: l.moneyFoodTotal,
                    value: money(context, t.foodTotal),
                    proof: l.moneyFoodProof,
                  ),
                  Figure(
                    label: l.moneyMealRate,
                    value: money(context, t.mealRate),
                    proof: l.moneyMealRateProof(
                      money(context, t.foodTotal),
                      Fmt.meals(t.totalMeals, banglaDigits: bn),
                    ),
                  ),
                ),
                _pair(
                  Figure(
                    label: l.moneyExtraTotal,
                    value: money(context, t.extraTotal),
                    proof: l.moneyExtraProof,
                  ),
                  Figure(
                    label: l.moneyDepositTotal,
                    value: money(context, t.creditTotal),
                    proof: l.moneyDepositProof,
                  ),
                ),
                if (t.unallocatedFood)
                  Text(
                    l.moneyNoMealsWarning,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.palette.warning,
                    ),
                  ),
              ],
            ),
          ),
        );
  }

  Widget _pair(Widget a, Widget b) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSpace.lg,
    children: [
      Expanded(child: a),
      Expanded(child: b),
    ],
  );
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

/// Rows with hairlines, then a "load more" button while there is more.
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
    return SliverList.list(
      children: [
        const Divider(),
        for (final i in items) ...[widget.row(i), const Divider()],
        if (widget.page.hasMore)
          Padding(
            padding: const EdgeInsets.all(AppSpace.gutter),
            child: AppButton(
              label: AppLocalizations.of(context).moneyLoadMore,
              variant: AppButtonVariant.secondary,
              loading: _loading,
              onPressed: _more,
            ),
          ),
      ],
    );
  }
}

/// A non-interactive tag (split, method, status).
class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.sm,
      vertical: AppSpace.xs / 2,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: context.palette.border),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(text, style: Theme.of(context).textTheme.labelSmall),
  );
}

Widget _row(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Widget trailing,
  VoidCallback? onTap,
  Widget? status,
}) => ListTile(
  minTileHeight: AppSize.touch + AppSpace.md,
  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
  title: Text(title, style: Theme.of(context).textTheme.titleSmall),
  subtitle: status == null
      ? Text(subtitle)
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(subtitle), status],
        ),
  trailing: trailing,
  onTap: onTap,
);

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
    return _asyncSliver(
      context,
      ref.watch(memberBalancesProvider(messId)),
      onRetry: () => ref.invalidate(memberBalancesProvider(messId)),
      data: (list) => list.isEmpty
          ? SliverToBoxAdapter(child: EmptyView(message: l.balanceEmpty))
          : SliverList.list(
              children: [
                const Divider(),
                for (final b in list) ...[
                  _row(
                    context,
                    title: b.displayName,
                    subtitle: l.balanceMeals(
                      Fmt.meals(b.meals, banglaDigits: bn),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Money(
                          b.closingBalance,
                          signed: true,
                          banglaDigits: bn,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          balanceWord(l, b.closingBalance),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    onTap: () => showBillSheet(context, messId, b),
                  ),
                  const Divider(),
                ],
              ],
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

class BillBreakdown extends ConsumerWidget {
  const BillBreakdown({super.key, required this.messId, required this.balance});

  final String messId;
  final MemberBalance balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = banglaDigits(context);
    final text = Theme.of(context).textTheme;
    final rate = ref.watch(monthTotalsProvider(messId)).value?.mealRate;
    String label(BillPart p) => switch (p) {
      BillPart.opening => l.balanceOpening,
      BillPart.credit => l.balanceCredit,
      BillPart.food => l.balanceFood(
        Fmt.meals(balance.meals, banglaDigits: bn),
        rate == null ? '…' : money(context, rate),
      ),
      BillPart.extra => l.balanceExtra,
    };
    Widget line(String name, Widget value, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        spacing: AppSpace.md,
        children: [
          Expanded(child: Text(name, style: style)),
          value,
        ],
      ),
    );
    return Column(
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
          ),
        const Divider(),
        line(
          '${l.balanceClosing} · ${balanceWord(l, balance.closingBalance)}',
          Money(
            balance.closingBalance,
            signed: true,
            banglaDigits: bn,
            style: text.titleMedium,
          ),
          style: text.titleSmall,
        ),
      ],
    );
  }
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
          title: names[b.buyerMemberId] ?? l.bazarTitle,
          subtitle: [
            shortDate(context, b.date),
            if (b.items.isNotEmpty)
              l.bazarItemCount(Fmt.digits('${b.items.length}', bangla: bn)),
            _paidFrom(l, names, b.paidByMemberId),
          ].join(' · '),
          trailing: Money(b.amount, banglaDigits: bn),
          status: SyncBadge(
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
    final bn = banglaDigits(context);
    final names = _names(ref, messId);
    final cats = {
      for (final c
          in ref.watch(expenseCategoriesProvider(messId)).value ?? const [])
        c.id: c.name,
    };
    final isManager = ref.watch(amIManagerProvider);
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
          title: cats[e.categoryId] ?? l.moneyTabExpense,
          subtitle: [
            shortDate(context, e.date),
            _paidFrom(l, names, e.paidByMemberId),
          ].join(' · '),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.sm,
            children: [
              _Tag(e.shares.isEmpty ? splitLabel(l, e.split) : l.splitSelected),
              Money(e.amount, banglaDigits: bn),
            ],
          ),
          onTap: isManager
              ? () => showExpenseForm(context, existing: e)
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
    final bn = banglaDigits(context);
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
          children: [
            _depositRow(context, l, bn, names, isManager, d),
            if (isManager && d.status == DepositStatus.pending)
              _VerifyActions(deposit: d, name: names[d.memberId] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _depositRow(
    BuildContext context,
    AppLocalizations l,
    bool bn,
    Map<String, String> names,
    bool isManager,
    Deposit d,
  ) => _row(
    context,
    title: names[d.memberId] ?? l.moneyTabDeposit,
    subtitle: [
      shortDate(context, d.date),
      if (d.trxId != null) 'TrxID ${d.trxId}',
      if (d.status == DepositStatus.pending) l.depositPending,
      if (d.status == DepositStatus.rejected) l.depositRejected,
    ].join(' · '),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.sm,
      children: [
        _Tag(methodLabel(l, d.method)),
        Money(d.amount, banglaDigits: bn),
      ],
    ),
    onTap: isManager
        ? () => showDepositForm(context, existing: d)
        : d.screenshotPath == null
        ? null
        : () => showReceipt(context, d.screenshotPath!),
  );
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
