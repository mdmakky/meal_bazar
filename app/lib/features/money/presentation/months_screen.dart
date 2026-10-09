import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart';
import '../../month/application/month_providers.dart';
import '../../month/presentation/month_status_chip.dart';
import '../../report/presentation/report_actions.dart';
import '../application/money_providers.dart';
import '../domain/money.dart';
import 'money_sheets.dart';

/// `/money/months`: the month waiting to be closed (review screen) and the
/// months history.
class MonthsScreen extends ConsumerStatefulWidget {
  const MonthsScreen({super.key});

  @override
  ConsumerState<MonthsScreen> createState() => _MonthsScreenState();
}

class _MonthsScreenState extends ConsumerState<MonthsScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final messId = ref.watch(currentMessIdProvider);
    final isManager = ref.watch(amIManagerProvider);
    final status = messId == null
        ? null
        : ref.watch(monthStatusProvider(messId)).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.monthTitle),
        actions: const [
          MonthStatusChip(),
          SizedBox(width: AppSpace.sm),
        ],
      ),
      body: messId == null
          ? EmptyView(message: l.moneyNoMess)
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpace.xxxl),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpace.gutter),
                  child: isManager
                      ? (status == null || status.isClosed
                            ? const SizedBox.shrink()
                            : AppButton(
                                key: const Key('months-review'),
                                label: l.monthEndReview,
                                icon: Icons.lock_outline,
                                onPressed: () =>
                                    context.go(monthReviewPath(status.start)),
                              ))
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
                      data: (months) {
                        // The period waiting to be closed leads, even before
                        // it has a `months` row.
                        final rest = [
                          for (final m in months)
                            if (m.start != status?.start) m,
                        ];
                        return status == null && rest.isEmpty
                            ? EmptyView(message: l.monthNoneClosed)
                            : StaggeredList(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.gutter,
                                  ),
                                  child: RaisedGroup(
                                    children: StaggeredList.wrap([
                                      if (status != null)
                                        _monthRow(
                                          context,
                                          messId,
                                          status.start,
                                          status.end,
                                          closed: status.isClosed,
                                          tag: status.isClosed
                                              ? l.monthStatusClosed
                                              : status.isCorrecting
                                              ? l.monthEndChipCorrecting
                                              : l.monthEndChipPending,
                                          isManager: isManager,
                                          month: months
                                              .where(
                                                (m) => m.start == status.start,
                                              )
                                              .firstOrNull,
                                          onTap: isManager
                                              ? () => context.go(
                                                  monthReviewPath(status.start),
                                                )
                                              : null,
                                        ),
                                      for (final m in rest)
                                        _monthRow(
                                          context,
                                          messId,
                                          m.start,
                                          m.end,
                                          closed: m.closed,
                                          tag: m.closed
                                              ? l.monthStatusClosed
                                              : l.monthStatusOpen,
                                          isManager: isManager,
                                          month: m,
                                        ),
                                    ]),
                                  ),
                                ),
                              );
                      },
                    ),
              ],
            ),
    );
  }

  Widget _monthRow(
    BuildContext context,
    String messId,
    DateTime start,
    DateTime end, {
    required bool closed,
    required String tag,
    required bool isManager,
    MessMonth? month,
    VoidCallback? onTap,
  }) {
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          spacing: AppSpace.md,
          children: [
            IconTile(closed ? Icons.lock_outline : Icons.lock_open_outlined),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.xs,
                children: [
                  Text(
                    rangeLabel(context, start, end),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  StatusTag(tag, strong: closed),
                ],
              ),
            ),
            if (ref.featureOn('pdf_report'))
              PopupMenuButton<bool>(
                tooltip: l.reportTitle,
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onSelected: (print) => print
                    ? printMonthReport(context, messId: messId, day: start)
                    : shareMonthReport(context, messId: messId, day: start),
                itemBuilder: (_) => [
                  PopupMenuItem(value: false, child: Text(l.reportShare)),
                  PopupMenuItem(value: true, child: Text(l.reportPrint)),
                ],
              ),
            if (isManager && closed && month != null)
              TextButton(
                onPressed: () => _reopen(context, messId, month),
                child: Text(l.monthReopen),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _reopen(BuildContext context, String messId, MessMonth m) async {
    final l = AppLocalizations.of(context);
    final done = await AppSheet.show<bool>(
      context,
      title: l.monthReopenTitle,
      child: ReopenMonthForm(messId: messId, month: m),
    );
    if (done == true && context.mounted) {
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
