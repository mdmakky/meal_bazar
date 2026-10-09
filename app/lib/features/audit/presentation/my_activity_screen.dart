import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart' show RaisedGroup;
import '../../messages/domain/message_draft.dart';
import '../../money/presentation/money_sheets.dart' show shortDate;
import '../application/audit_providers.dart';
import '../domain/audit.dart';

/// "আমার বিষয়ে এন্ট্রি", in full: every entry others made about me.
class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final Widget body;
    if (messId == null) {
      body = EmptyView(message: l.moneyNoMess);
    } else {
      final names = ref.watch(auditNamesProvider(messId));
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(myActivityProvider(messId).future),
        child: ref
            .watch(myActivityProvider(messId))
            .when(
              skipLoadingOnRefresh: true,
              loading: () => const LoadingView(rows: 6),
              error: (e, _) => ErrorView(
                message: failureText(context, e),
                onRetry: () => ref.invalidate(myActivityProvider(messId)),
              ),
              data: (items) => items.isEmpty
                  ? EmptyView(icon: Icons.history, message: l.activityEmpty)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.gutter,
                        AppSpace.sm,
                        AppSpace.gutter,
                        AppSpace.xxl,
                      ),
                      children: [
                        RaisedGroup(
                          inset: AppSpace.lg,
                          children: [
                            for (final e in items)
                              ActivityRow(
                                key: ValueKey('act-${e.id}'),
                                entry: e,
                                names: names,
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.activityTitle)),
      body: body,
    );
  }
}

/// One entry about me: the sentence ("রাকিব আপনার মিল বদলেছেন ½ → ১"), when,
/// and a compact flag to report a problem with it.
class ActivityRow extends ConsumerWidget {
  const ActivityRow({super.key, required this.entry, required this.names});

  final AuditEntry entry;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    final at = entry.at.toLocal();
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(at));
    final when = '${shortDate(context, at)}, ${Fmt.digits(time, bangla: bn)}';
    final sentence = describeAudit(
      l,
      entry,
      names,
      selfId: ref.watch(currentMembershipProvider)?.member.id,
      omitSameDay: true,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(sentence, style: text.bodyMedium),
                  Text(
                    when,
                    style: text.labelSmall?.copyWith(color: p.inkTertiary),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: l.reportProblem,
            icon: Icon(Icons.flag_outlined, size: 20, color: p.inkTertiary),
            onPressed: () => context.push(
              '/more/messages/new',
              extra: MessageDraft(
                refType: entry.refType ?? 'other',
                refId: entry.refId,
                refLabel: sentence,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
