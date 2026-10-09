import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart';
import '../../money/application/money_providers.dart';
import '../../money/presentation/money_sheets.dart'
    show banglaDigits, longDate, money, shortDate;
import '../../money/presentation/months_screen.dart'
    show ReopenMonthForm, rangeLabel;
import '../../report/presentation/report_actions.dart';
import '../application/month_providers.dart';
import '../domain/month.dart';

/// `/money/months/review`: everything a manager checks before closing a
/// month (issues, totals, member balances), the close itself, and, once
/// closed, the final report. Figures all come from SQL.
class MonthEndReviewScreen extends ConsumerStatefulWidget {
  const MonthEndReviewScreen({super.key, this.start});

  /// ponytail: only the period `month_review` names is reviewable; a
  /// different [start] falls back to it.
  final DateTime? start;

  @override
  ConsumerState<MonthEndReviewScreen> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<MonthEndReviewScreen> {
  var _confirmMissing = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final isManager = ref.watch(amIManagerProvider);
    Widget body;
    if (messId == null) {
      body = EmptyView(message: l.moneyNoMess);
    } else if (!isManager) {
      body = EmptyView(message: l.monthManagerOnly);
    } else {
      body = ref
          .watch(monthStatusProvider(messId))
          .when(
            skipLoadingOnRefresh: true,
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: failureText(context, e),
              onRetry: () => ref.invalidate(monthStatusProvider(messId)),
            ),
            data: (s) => s == null
                ? EmptyView(message: l.monthEndNoPeriod)
                : _content(context, messId, s),
          );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.monthEndTitle)),
      body: body,
    );
  }

  Widget _content(BuildContext context, String messId, MonthStatus s) {
    final summary = ref.watch(
      periodSummaryProvider((messId: messId, start: s.start)),
    );
    final balances = summary.value?.$3;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monthStatusProvider(messId));
        ref.invalidate(periodSummaryProvider);
        ref.invalidate(monthMissingMealsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.md,
          AppSpace.gutter,
          AppSpace.xxxl,
        ),
        children: [
          _Header(status: s, messId: messId),
          _section(context, AppLocalizations.of(context).monthEndTotals),
          _Totals(totals: s.totals),
          if (!s.isClosed) ...[
            _section(context, AppLocalizations.of(context).monthEndIssues),
            _Issues(messId: messId, status: s),
          ],
          _section(
            context,
            AppLocalizations.of(context).monthEndBalances,
            strong: s.isClosed,
            tag: s.isClosed
                ? AppLocalizations.of(context).monthEndFinal
                : AppLocalizations.of(context).monthEndProvisional,
          ),
          summary.when(
            skipLoadingOnRefresh: true,
            loading: () => const LoadingView(rows: 3),
            error: (e, _) => ErrorView(
              message: failureText(context, e),
              onRetry: () => ref.invalidate(periodSummaryProvider),
            ),
            data: (r) => _BalanceTable(balances: r.$3),
          ),
          const SizedBox(height: AppSpace.xl),
          if (s.isClosed)
            _ClosedActions(messId: messId, status: s)
          else
            _CloseActions(
              messId: messId,
              status: s,
              balances: balances,
              confirmMissing: _confirmMissing,
              onConfirmMissing: (v) => setState(() => _confirmMissing = v),
            ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title, {
    String? tag,
    bool strong = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.md),
    child: Row(
      spacing: AppSpace.sm,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        if (tag != null) StatusTag(tag, strong: strong),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.status, required this.messId});

  final MonthStatus status;
  final String messId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final s = status;
    final name = Fmt.monthName(
      s.start,
      locale: Localizations.localeOf(context).languageCode,
    );
    final badge = s.isClosed
        ? l.monthStatusClosed
        : s.isCorrecting
        ? l.monthEndChipCorrecting
        : l.monthStatusOpen;
    Widget note(IconData icon, String t, Color c) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.sm,
      children: [
        Icon(icon, size: 18, color: c),
        Expanded(
          child: Text(t, style: text.bodyMedium?.copyWith(color: c)),
        ),
      ],
    );
    final closedAt = s.closedAt;
    return AppCard.raised(
      key: const Key('review-header'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.sm,
        children: [
          Row(
            spacing: AppSpace.md,
            children: [
              Expanded(child: Text(name, style: text.titleLarge)),
              StatusTag(badge, strong: s.isClosed),
            ],
          ),
          Text(
            rangeLabel(context, s.start, s.end),
            style: text.bodyMedium?.copyWith(color: p.inkSecondary),
          ),
          if (closedAt != null)
            Text(
              l.monthEndClosedAt(
                '${longDate(context, closedAt)} '
                '${Fmt.digits('${closedAt.hour.toString().padLeft(2, '0')}:${closedAt.minute.toString().padLeft(2, '0')}', bangla: banglaDigits(context))}',
              ),
              style: text.bodyMedium?.copyWith(color: p.inkSecondary),
            ),
          if (s.totalsReconstructed)
            note(Icons.info_outline, l.monthEndReconstructed, p.warning),
          if (s.openingProvisional)
            note(Icons.info_outline, l.monthEndOpeningProvisional, p.warning),
          if (s.isCorrecting) _CorrectionBanner(status: s, messId: messId),
        ],
      ),
    );
  }
}

class _CorrectionBanner extends ConsumerWidget {
  const _CorrectionBanner({required this.status, required this.messId});

  final MonthStatus status;
  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final reason = (ref.watch(monthsProvider(messId)).value ?? const [])
        .where((m) => m.start == status.start)
        .firstOrNull
        ?.reopenReason;
    return Container(
      key: const Key('correction-banner'),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: p.accentSoft,
        border: Border.all(color: p.accent),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.xs,
        children: [
          Text(l.monthEndCorrectionTitle, style: text.titleSmall),
          if (reason != null && reason.isNotEmpty)
            Text(l.monthEndCorrectionReason(reason), style: text.bodyMedium),
          Text(l.monthEndCorrectionBody, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.totals});

  final MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bn = banglaDigits(context);
    final t = totals;
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: _tab(context)),
        ],
      ),
    );
    return RaisedGroup(
      children: [
        row(l.moneyFoodTotal, money(context, t.foodTotal)),
        row(l.monthTotalMeals, Fmt.meals(t.totalMeals, banglaDigits: bn)),
        row(l.moneyMealRate, money(context, t.mealRate)),
        row(l.moneyExtraTotal, money(context, t.extraTotal)),
        row(l.moneyDepositTotal, money(context, t.creditTotal)),
      ],
    );
  }
}

TextStyle? _tab(BuildContext context) => Theme.of(context).textTheme.bodyLarge
    ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

class _Issues extends ConsumerWidget {
  const _Issues({required this.messId, required this.status});

  final String messId;
  final MonthStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final s = status;
    final bn = banglaDigits(context);
    String n(int v) => Fmt.digits('$v', bangla: bn);

    Widget card(
      IconData icon,
      String title, {
      String? body,
      String? action,
      VoidCallback? onTap,
      Widget? extra,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.sm,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.md,
              children: [
                Icon(icon, color: p.warning),
                Expanded(child: Text(title, style: text.titleSmall)),
              ],
            ),
            if (body != null)
              Text(
                body,
                style: text.bodyMedium?.copyWith(color: p.inkSecondary),
              ),
            ?extra,
            if (action != null)
              AppButton(
                label: action,
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: onTap,
              ),
          ],
        ),
      ),
    );

    final autoText = switch (s.autoState) {
      'pending' => l.monthEndAutoPending,
      'incomplete' => l.monthEndAutoIncomplete,
      'failed' => l.monthEndAutoFailed,
      _ => null,
    };
    final cards = <Widget>[
      if (s.pendingDeposits > 0)
        card(
          Icons.savings_outlined,
          l.monthEndPendingDeposits(n(s.pendingDeposits)),
          action: l.monthEndReviewDeposits,
          onTap: () => context.go('/money?tab=deposit'),
        ),
      if (s.pendingBazarRequests > 0)
        card(
          Icons.shopping_basket_outlined,
          l.monthEndPendingBazar(n(s.pendingBazarRequests)),
          action: l.monthEndReviewBazar,
          onTap: () => context.go('/bazar'),
        ),
      if (s.missingDays > 0)
        card(
          Icons.restaurant_outlined,
          l.monthEndMissingTitle(n(s.missingDays)),
          body: l.monthEndMissingHelp,
          extra: _MissingList(messId: messId, start: s.start),
        ),
      if (autoText != null) card(Icons.schedule, autoText),
      if (s.autoBadDays > 0)
        card(
          Icons.warning_amber_rounded,
          l.monthEndAutoBadDays(n(s.autoBadDays)),
        ),
    ];
    if (cards.isEmpty) {
      return AppCard(
        key: const Key('review-ready'),
        child: Row(
          spacing: AppSpace.md,
          children: [
            Icon(Icons.check_circle_outline, color: p.advance),
            Expanded(child: Text(l.monthEndReady, style: text.titleSmall)),
          ],
        ),
      );
    }
    return Column(children: cards);
  }
}

class _MissingList extends ConsumerWidget {
  const _MissingList({required this.messId, required this.start});

  final String messId;
  final DateTime start;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return ref
        .watch(monthMissingMealsProvider((messId: messId, start: start)))
        .when(
          skipLoadingOnRefresh: true,
          loading: () => const LoadingView(rows: 1),
          error: (e, _) => ErrorView(
            message: failureText(context, e),
            onRetry: () => ref.invalidate(monthMissingMealsProvider),
          ),
          data: (rows) {
            final byDay = <DateTime, List<String>>{};
            for (final r in rows) {
              (byDay[r.day] ??= []).add(r.name);
            }
            return Column(
              children: [
                for (final e in byDay.entries)
                  InkWell(
                    key: Key('missing-${isoDate(e.key)}'),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => context.go('/meals?date=${isoDate(e.key)}'),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSize.touch,
                      ),
                      child: Row(
                        spacing: AppSpace.md,
                        children: [
                          Text(
                            shortDate(context, e.key),
                            style: text.labelLarge,
                          ),
                          Expanded(
                            child: Text(
                              e.value.join(', '),
                              style: text.bodyMedium?.copyWith(
                                color: p.inkSecondary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: p.inkTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
  }
}

class _BalanceTable extends StatelessWidget {
  const _BalanceTable({required this.balances});

  final List<MemberBalance> balances;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = banglaDigits(context);
    double sum(double Function(MemberBalance) f) =>
        balances.fold(0, (a, b) => a + f(b));
    Widget cell(String t, {TextStyle? style, Alignment? align}) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.sm,
      ),
      child: Align(
        alignment: align ?? Alignment.centerRight,
        child: Text(
          t,
          style: (style ?? text.bodyMedium)?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
    Widget fin(double v, {bool bold = false}) => cell(
      '${v > 0
          ? '+'
          : v < 0
          ? '−'
          : ''}${Fmt.money(v.abs(), banglaDigits: bn)}',
      style: (bold ? text.titleSmall : text.bodyMedium)?.copyWith(
        color: v > 0 ? p.advance : (v < 0 ? p.due : null),
      ),
    );
    TableRow row(
      String name,
      double meals,
      double cost,
      double paid,
      double opening,
      double fnl, {
      bool head = false,
    }) => TableRow(
      decoration: head
          ? BoxDecoration(
              border: Border(top: BorderSide(color: p.borderStrong)),
            )
          : null,
      children: [
        cell(
          name,
          align: Alignment.centerLeft,
          style: head ? text.titleSmall : text.bodyMedium,
        ),
        // The final balance is the figure that matters, so it sits next to
        // the name and is always visible; the working scrolls sideways.
        fin(fnl, bold: head),
        cell(Fmt.meals(meals, banglaDigits: bn)),
        cell(Fmt.money(cost, banglaDigits: bn)),
        cell(Fmt.money(paid, banglaDigits: bn)),
        cell(Fmt.money(opening, banglaDigits: bn)),
      ],
    );
    final header = TableRow(
      children: [
        for (final (i, t) in [
          l.monthEndColMember,
          l.monthEndColFinal,
          l.monthEndColMeals,
          l.monthEndColCost,
          l.monthEndColPaid,
          l.monthEndColOpening,
        ].indexed)
          cell(
            t,
            style: AppType.overline(context),
            align: i == 0 ? Alignment.centerLeft : null,
          ),
      ],
    );
    return AppCard(
      key: const Key('balance-table'),
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(84),
          columnWidths: const {0: FixedColumnWidth(120)},
          children: [
            header,
            for (final b in balances)
              row(
                b.displayName,
                b.meals,
                b.foodCost + b.extraCost,
                b.credit,
                b.openingBalance,
                b.closingBalance,
              ),
            row(
              l.monthEndTotalRow,
              sum((b) => b.meals),
              sum((b) => b.foodCost + b.extraCost),
              sum((b) => b.credit),
              sum((b) => b.openingBalance),
              sum((b) => b.closingBalance),
              head: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseActions extends ConsumerWidget {
  const _CloseActions({
    required this.messId,
    required this.status,
    required this.balances,
    required this.confirmMissing,
    required this.onConfirmMissing,
  });

  final String messId;
  final MonthStatus status;
  final List<MemberBalance>? balances;
  final bool confirmMissing;
  final ValueChanged<bool> onConfirmMissing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final s = status;
    final n = Fmt.digits('${s.missingDays}', bangla: banglaDigits(context));
    final pendingBlock = s.pendingDeposits + s.pendingBazarRequests > 0;
    final needsTick = s.missingDays > 0 && !confirmMissing;
    final reason = pendingBlock
        ? l.monthEndBlockedPending
        : s.autoBlocks
        ? l.monthEndBlockedAuto
        : needsTick
        ? l.monthEndBlockedConfirm
        : null;
    final ready = !pendingBlock && !s.autoBlocks && !needsTick && s.canClose;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.md,
      children: [
        if (s.missingDays > 0)
          CheckboxListTile(
            key: const Key('confirm-missing'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: confirmMissing,
            onChanged: (v) => onConfirmMissing(v ?? false),
            title: Text(l.monthEndConfirmMissing(n)),
          ),
        AppButton(
          key: const Key('review-close'),
          label: l.monthClose,
          icon: Icons.lock_outline,
          expand: true,
          onPressed: ready && balances != null
              ? () async {
                  final done = await AppSheet.show<bool>(
                    context,
                    title: l.monthEndConfirmTitle(
                      Fmt.monthName(
                        s.start,
                        locale: Localizations.localeOf(context).languageCode,
                      ),
                    ),
                    child: _ConfirmClose(
                      messId: messId,
                      status: s,
                      balances: balances!,
                      confirmMissing: confirmMissing,
                    ),
                  );
                  if (done == true && context.mounted) {
                    showSnack(context, l.monthClosedDone);
                  }
                }
              : null,
        ),
        if (reason != null)
          Text(
            reason,
            key: const Key('close-blocked-reason'),
            style: text.bodyMedium?.copyWith(color: p.inkSecondary),
          ),
      ],
    );
  }
}

/// The last look before closing: the final figures and what closing does.
class _ConfirmClose extends ConsumerStatefulWidget {
  const _ConfirmClose({
    required this.messId,
    required this.status,
    required this.balances,
    required this.confirmMissing,
  });

  final String messId;
  final MonthStatus status;
  final List<MemberBalance> balances;
  final bool confirmMissing;

  @override
  ConsumerState<_ConfirmClose> createState() => _ConfirmCloseState();
}

class _ConfirmCloseState extends ConsumerState<_ConfirmClose> {
  var _saving = false;
  Object? _error;

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(moneyControllerProvider)
          .closeMonth(
            widget.messId,
            widget.status.start,
            confirmMissing: widget.confirmMissing,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = banglaDigits(context);
    final t = widget.status.totals;
    Widget line(String k, String v, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: _tab(context)?.copyWith(color: color)),
        ],
      ),
    );
    Widget point(IconData icon, String s) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.sm,
      children: [
        Icon(icon, size: 18, color: p.inkSecondary),
        Expanded(
          child: Text(
            s,
            style: text.bodyMedium?.copyWith(color: p.inkSecondary),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.md,
      children: [
        Text(l.monthEndConfirmFinalFigures, style: text.labelLarge),
        Column(
          children: [
            line(l.moneyFoodTotal, money(context, t.foodTotal)),
            line(l.monthTotalMeals, Fmt.meals(t.totalMeals, banglaDigits: bn)),
            line(l.moneyMealRate, money(context, t.mealRate)),
            line(l.moneyExtraTotal, money(context, t.extraTotal)),
            line(l.moneyDepositTotal, money(context, t.creditTotal)),
            const Divider(),
            for (final b in widget.balances)
              line(
                b.displayName,
                '${b.closingBalance > 0
                    ? '+'
                    : b.closingBalance < 0
                    ? '−'
                    : ''}${Fmt.money(b.closingBalance.abs(), banglaDigits: bn)}',
                color: b.closingBalance > 0
                    ? p.advance
                    : (b.closingBalance < 0 ? p.due : null),
              ),
          ],
        ),
        if (widget.confirmMissing && widget.status.missingDays > 0)
          Text(
            l.monthEndConfirmMissingNote(
              Fmt.digits('${widget.status.missingDays}', bangla: bn),
            ),
            style: text.bodyMedium?.copyWith(color: p.warning),
          ),
        Text(l.closeMonthWhatHappens, style: text.labelLarge),
        point(Icons.verified_outlined, l.closeMonthFinal),
        point(Icons.lock_outline, l.closeMonthLocked),
        point(Icons.redo, l.closeMonthCarry),
        point(Icons.notifications_none, l.closeMonthNotify),
        if (_error != null)
          Text(
            failureText(context, _error!),
            style: text.bodyMedium?.copyWith(color: p.due),
          ),
        AppButton(
          key: const Key('confirm-close'),
          label: l.monthClose,
          loading: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Closed: when, with how many gaps, the PDF, and reopen.
class _ClosedActions extends ConsumerWidget {
  const _ClosedActions({required this.messId, required this.status});

  final String messId;
  final MonthStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final month = (ref.watch(monthsProvider(messId)).value ?? const [])
        .where((m) => m.start == status.start)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.md,
      children: [
        Text(l.monthEndFinalReport, style: text.titleMedium),
        if (status.closedMissing > 0)
          Text(
            l.monthEndClosedMissing(
              Fmt.digits(
                '${status.closedMissing}',
                bangla: banglaDigits(context),
              ),
            ),
            key: const Key('closed-missing'),
            style: text.bodyMedium?.copyWith(color: p.inkSecondary),
          ),
        if (ref.featureOn('pdf_report'))
          AppButton(
            label: l.lastMonthReport,
            icon: Icons.picture_as_pdf_outlined,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () =>
                shareMonthReport(context, messId: messId, day: status.start),
          ),
        AppButton(
          key: const Key('review-reopen'),
          label: l.monthReopen,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: month == null
              ? null
              : () async {
                  final done = await AppSheet.show<bool>(
                    context,
                    title: l.monthReopenTitle,
                    child: ReopenMonthForm(messId: messId, month: month),
                  );
                  if (done == true && context.mounted) {
                    showSnack(context, l.monthReopened);
                  }
                },
        ),
      ],
    );
  }
}
