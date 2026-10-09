import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart'
    show InitialsAvatar, RaisedGroup, StatusTag;
import '../application/audit_providers.dart';
import '../domain/audit.dart';
import 'my_activity_screen.dart';

/// Who did what, newest first. Managers only in the app (RLS still lets every
/// member read it); a member who deep-links here gets [MyActivityScreen].
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  var _filter = AuditFilter.all;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(amIManagerProvider)) return const MyActivityScreen();
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);

    final labels = {
      AuditFilter.all: l.auditFilterAll,
      AuditFilter.meals: l.auditFilterMeals,
      AuditFilter.money: l.auditFilterMoney,
      AuditFilter.members: l.auditFilterMembers,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.auditTitle)),
      body: messId == null
          ? EmptyView(message: l.emptyGeneric)
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.gutter,
                    vertical: AppSpace.sm,
                  ),
                  child: Row(
                    spacing: AppSpace.sm,
                    children: [
                      for (final f in AuditFilter.values)
                        ChoiceChip(
                          label: Text(labels[f]!),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _Feed(messId: messId, filter: _filter),
                ),
              ],
            ),
    );
  }
}

class _Feed extends ConsumerWidget {
  const _Feed({required this.messId, required this.filter});

  final String messId;
  final AuditFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final key = (messId, filter);
    final names = ref.watch(auditNamesProvider(messId));

    return switch (ref.watch(auditFeedProvider(key))) {
      AsyncValue(:final value?) when value.items.isEmpty => EmptyView(
        message: l.auditEmpty,
        icon: Icons.history,
      ),
      AsyncValue(:final value?) => RefreshIndicator(
        onRefresh: () => ref.refresh(auditFeedProvider(key).future),
        // ponytail: one Column per loaded page set; fine at audit page sizes.
        child: StaggeredList(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.sm,
              AppSpace.gutter,
              AppSpace.xl,
            ),
            children: [
              RaisedGroup(
                children: [
                  for (final (i, e) in value.items.indexed)
                    Stagger(
                      index: i,
                      child: AuditTile(entry: e, names: names),
                    ),
                ],
              ),
              if (value.hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.md),
                  child: AppButton(
                    label: l.auditLoadMore,
                    variant: AppButtonVariant.text,
                    onPressed: () =>
                        ref.read(auditFeedProvider(key).notifier).loadMore(),
                  ),
                ),
            ],
          ),
        ),
      ),
      AsyncValue(:final error?) => ErrorView(
        message: failureText(context, error),
        onRetry: () => ref.invalidate(auditFeedProvider(key)),
      ),
      _ => const LoadingView(),
    };
  }
}

class AuditTile extends StatelessWidget {
  const AuditTile({super.key, required this.entry, required this.names});

  final AuditEntry entry;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final bn = l.localeName == 'bn';
    final at = entry.at.toLocal();
    final when =
        '${Fmt.dateLong(at, locale: l.localeName, banglaDigits: bn)}, '
        '${Fmt.digits(MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(at)), bangla: bn)}';
    final reason = entry.reason;

    final actor = entry.actorId == null
        ? l.auditSystem
        : names[entry.actorId] ?? l.auditSomeone;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.md,
        children: [
          InitialsAvatar(actor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.xs,
              children: [
                Text(describeAudit(l, entry, names), style: text.bodyLarge),
                if (reason != null && reason.isNotEmpty)
                  Text(
                    l.auditReason(reason),
                    style: text.bodyMedium?.copyWith(color: p.inkSecondary),
                  ),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      when,
                      style: text.labelSmall?.copyWith(color: p.inkTertiary),
                    ),
                    if (entry.source == 'ai') StatusTag(l.auditAi),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
