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
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart' show PendingItems;
import '../../report/presentation/report_actions.dart';
import '../application/money_providers.dart';
import '../domain/money.dart';
import 'money_sheets.dart';

/// `/money/months`: close the month (manager) and the closed-months history.
/// A successful close lands the বন্ধ stamp.
class MonthsScreen extends ConsumerStatefulWidget {
  const MonthsScreen({super.key});

  @override
  ConsumerState<MonthsScreen> createState() => _MonthsScreenState();
}

class _MonthsScreenState extends ConsumerState<MonthsScreen> {
  var _justClosed = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final messId = ref.watch(currentMessIdProvider);
    final isManager = ref.watch(amIManagerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.monthTitle)),
      body: messId == null
          ? EmptyView(message: l.moneyNoMess)
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpace.xxxl),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpace.gutter),
                  child: _justClosed
                      ? AppCard.raised(
                          padding: const EdgeInsets.all(AppSpace.xl),
                          child: Row(
                            spacing: AppSpace.lg,
                            children: [
                              Expanded(
                                child: Text(
                                  l.monthClosedDone,
                                  style: text.titleMedium,
                                ),
                              ),
                              StampMark(l.monthStatusClosed),
                            ],
                          ),
                        )
                      : isManager
                      ? AppButton(
                          label: l.monthClose,
                          icon: Icons.lock_outline,
                          onPressed: () => _close(context, messId),
                        )
                      : Text(
                          l.monthManagerOnly,
                          style: text.bodyMedium?.copyWith(
                            color: p.inkSecondary,
                          ),
                        ),
                ),
                SectionTitle(l.monthHistory),
                ref
                    .watch(monthsProvider(messId))
                    .when(
                      skipLoadingOnRefresh: true,
                      loading: () => const LoadingView(),
                      error: (e, _) => ErrorView(
                        message: failureText(context, e),
                        onRetry: () => ref.invalidate(monthsProvider(messId)),
                      ),
                      data: (months) => months.isEmpty
                          ? EmptyView(message: l.monthNoneClosed)
                          : StaggeredList(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.gutter,
                                ),
                                child: RaisedGroup(
                                  children: StaggeredList.wrap([
                                    for (final m in months)
                                      _monthRow(context, messId, m, isManager),
                                  ]),
                                ),
                              ),
                            ),
                    ),
              ],
            ),
    );
  }

  Widget _monthRow(
    BuildContext context,
    String messId,
    MessMonth m,
    bool isManager,
  ) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        spacing: AppSpace.md,
        children: [
          IconTile(m.closed ? Icons.lock_outline : Icons.lock_open_outlined),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.xs,
              children: [
                Text(
                  rangeLabel(context, m.start, m.end),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                StatusTag(
                  m.closed ? l.monthStatusClosed : l.monthStatusOpen,
                  strong: m.closed,
                ),
              ],
            ),
          ),
          if (ref.featureOn('pdf_report'))
            PopupMenuButton<bool>(
              tooltip: l.reportTitle,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onSelected: (print) => print
                  ? printMonthReport(context, messId: messId, day: m.start)
                  : shareMonthReport(context, messId: messId, day: m.start),
              itemBuilder: (_) => [
                PopupMenuItem(value: false, child: Text(l.reportShare)),
                PopupMenuItem(value: true, child: Text(l.reportPrint)),
              ],
            ),
          if (isManager && m.closed)
            TextButton(
              onPressed: () => _reopen(context, messId, m),
              child: Text(l.monthReopen),
            ),
        ],
      ),
    );
  }

  Future<void> _close(BuildContext context, String messId) async {
    final l = AppLocalizations.of(context);
    final done = await showCloseMonthSheet(context, messId);
    if (done && context.mounted) {
      setState(() => _justClosed = true);
      showSnack(context, l.monthClosedDone);
    }
  }

  Future<void> _reopen(BuildContext context, String messId, MessMonth m) async {
    final l = AppLocalizations.of(context);
    final done = await AppSheet.show<bool>(
      context,
      title: l.monthReopenTitle,
      child: ReopenMonthForm(messId: messId, month: m),
    );
    if (done == true && context.mounted) {
      setState(() => _justClosed = false);
      showSnack(context, l.monthReopened);
    }
  }
}

/// "১ অক্টোবর ২০২৬ – ৩১ অক্টোবর ২০২৬" for `[start, end)`.
String rangeLabel(BuildContext context, DateTime start, DateTime end) =>
    AppLocalizations.of(context).monthRange(
      longDate(context, start),
      longDate(context, end.subtract(const Duration(days: 1))),
    );

/// The close-month confirmation sheet; true once the month is closed.
/// [previous] preselects the month just ended (Home's call to action).
Future<bool> showCloseMonthSheet(
  BuildContext context,
  String messId, {
  bool? previous,
}) async =>
    await AppSheet.show<bool>(
      context,
      title: AppLocalizations.of(context).monthClose,
      child: CloseMonthForm(messId: messId, previous: previous),
    ) ==
    true;

/// What still blocks closing: pending deposits (→ হিসাব) and bazar requests
/// (→ বাজার), each a link. Nothing when both are zero.
class PendingItemsBlock extends StatelessWidget {
  const PendingItemsBlock({
    super.key,
    required this.pending,
    this.beforeNavigate,
  });

  final PendingItems pending;

  /// Runs before going to a tab (the sheet pops itself first).
  final VoidCallback? beforeNavigate;

  @override
  Widget build(BuildContext context) {
    if (pending.deposits + pending.bazarRequests == 0) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = banglaDigits(context);
    Widget link(String label, IconData icon, String route) => InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () {
        final router = GoRouter.of(context);
        beforeNavigate?.call();
        router.go(route);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.touch),
        child: Row(
          spacing: AppSpace.sm,
          children: [
            Icon(icon, size: 20, color: p.warning),
            Expanded(child: Text(label, style: text.bodyMedium)),
            Icon(Icons.chevron_right, size: 20, color: p.inkTertiary),
          ],
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.md,
        AppSpace.sm,
        AppSpace.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: p.warning),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.closeMonthPendingTitle,
            style: text.labelLarge?.copyWith(color: p.warning),
          ),
          if (pending.deposits > 0)
            link(
              l.closeMonthPendingDeposits(
                Fmt.digits('${pending.deposits}', bangla: bn),
              ),
              Icons.savings_outlined,
              '/money',
            ),
          if (pending.bazarRequests > 0)
            link(
              l.closeMonthPendingBazar(
                Fmt.digits('${pending.bazarRequests}', bangla: bn),
              ),
              Icons.shopping_basket_outlined,
              '/bazar',
            ),
        ],
      ),
    );
  }
}

/// Confirmation: pick the month, read its SQL totals, say what closing does,
/// show what still blocks it, then close it.
class CloseMonthForm extends ConsumerStatefulWidget {
  const CloseMonthForm({super.key, required this.messId, this.previous});

  final String messId;
  final bool? previous;

  @override
  ConsumerState<CloseMonthForm> createState() => _CloseMonthFormState();
}

class _CloseMonthFormState extends ConsumerState<CloseMonthForm> {
  late bool? _previous = widget.previous;
  var _saving = false;
  Object? _error;

  Future<void> _submit(DateTime day) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(moneyControllerProvider).closeMonth(widget.messId, day);
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
    final text = Theme.of(context).textTheme;
    final bn = banglaDigits(context);
    final current = ref.watch(currentPeriodProvider(widget.messId)).value;
    // Early in a month the manager is usually closing the one just ended.
    final previous =
        _previous ??
        (current != null && today().difference(current.start).inDays < 7);
    final day = previous && current != null
        ? current.start.subtract(const Duration(days: 1))
        : today();
    final totals = ref.watch(
      periodTotalsProvider((messId: widget.messId, day: day)),
    );
    final period = totals.value?.$1;
    // Unknown (offline) counts as none: close_month still refuses.
    final pending = period == null
        ? null
        : ref
              .watch(
                pendingItemsProvider((
                  messId: widget.messId,
                  from: period.start,
                  to: period.end,
                )),
              )
              .value;
    final blocked =
        pending != null && pending.deposits + pending.bazarRequests > 0;
    final p = context.palette;
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
    Widget line(String name, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text(
            value,
            style: text.bodyLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.md,
      children: [
        Wrap(
          spacing: AppSpace.sm,
          children: [
            ChoiceChip(
              label: Text(l.monthPrevious),
              selected: previous,
              onSelected: (_) => setState(() => _previous = true),
            ),
            ChoiceChip(
              label: Text(l.monthThis),
              selected: !previous,
              onSelected: (_) => setState(() => _previous = false),
            ),
          ],
        ),
        totals.when(
          loading: () => const LoadingView(rows: 1),
          error: (e, _) => ErrorView(
            message: failureText(context, e),
            onRetry: () => ref.invalidate(periodTotalsProvider),
          ),
          data: (r) {
            final (period, t) = r;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  rangeLabel(context, period.start, period.end),
                  style: text.titleSmall,
                ),
                const SizedBox(height: AppSpace.sm),
                line(l.moneyFoodTotal, money(context, t.foodTotal)),
                line(
                  l.monthTotalMeals,
                  Fmt.meals(t.totalMeals, banglaDigits: bn),
                ),
                line(
                  l.moneyMealRate,
                  [
                    money(context, t.mealRate),
                    if (t.fixedRate) '(${l.rateFixed})',
                  ].join(' '),
                ),
                line(l.moneyExtraTotal, money(context, t.extraTotal)),
                line(l.moneyDepositTotal, money(context, t.creditTotal)),
              ],
            );
          },
        ),
        Text(l.closeMonthWhatHappens, style: text.labelLarge),
        point(Icons.verified_outlined, l.closeMonthFinal),
        point(Icons.lock_outline, l.closeMonthLocked),
        point(Icons.redo, l.closeMonthCarry),
        point(Icons.notifications_none, l.closeMonthNotify),
        if (pending != null)
          PendingItemsBlock(
            pending: pending,
            beforeNavigate: () => Navigator.pop(context, false),
          ),
        if (_error != null)
          Text(
            failureText(context, _error!),
            style: text.bodyMedium?.copyWith(color: context.palette.due),
          ),
        AppButton(
          key: const Key('confirm-close'),
          label: l.monthClose,
          loading: _saving,
          onPressed: totals.hasValue && !blocked ? () => _submit(day) : null,
        ),
      ],
    );
  }
}

/// Reopen needs a reason of at least 5 characters (audit-logged).
class ReopenMonthForm extends ConsumerStatefulWidget {
  const ReopenMonthForm({super.key, required this.messId, required this.month});

  final String messId;
  final MessMonth month;

  @override
  ConsumerState<ReopenMonthForm> createState() => _ReopenMonthFormState();
}

class _ReopenMonthFormState extends ConsumerState<ReopenMonthForm> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  var _saving = false;
  Object? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(moneyControllerProvider)
          .reopenMonth(widget.messId, widget.month.id, _reason.text);
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
    final text = Theme.of(context).textTheme;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Text(
            rangeLabel(context, widget.month.start, widget.month.end),
            style: text.titleSmall,
          ),
          TextFormField(
            controller: _reason,
            autofocus: true,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: l.monthReopenReason,
              helperText: l.monthReopenReasonHelp,
              helperMaxLines: 2,
            ),
            validator: (v) =>
                (v ?? '').trim().length < 5 ? l.monthReopenReasonShort : null,
          ),
          if (_error != null)
            Text(
              failureText(context, _error!),
              style: text.bodyMedium?.copyWith(color: context.palette.due),
            ),
          AppButton(label: l.monthReopen, loading: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}
