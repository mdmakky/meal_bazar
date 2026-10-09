import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/sync.dart';
import 'l10n/gen/app_localizations.dart';
import 'widgets/widgets.dart';

/// One app-wide line above the tab bar while writes wait in the sync queue:
/// "offline, N changes saved on this phone", "sending N…", or "N could not
/// be sent" with a retry. Nothing when the queue is empty.
class SyncStrip extends ConsumerWidget {
  const SyncStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = ref.watch(syncQueueProvider).value ?? const [];
    final state = queueState(ops);
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final n = Fmt.digits('${ops.length}', bangla: l.localeName == 'bn');

    final (
      IconData? icon,
      String label,
      Color tone,
      String? action,
    ) = switch (state) {
      SyncState.synced => (null, '', p.inkSecondary, null),
      SyncState.syncing => (
        Icons.cloud_upload_outlined,
        l.syncStripSending(n),
        p.inkSecondary,
        null,
      ),
      SyncState.offline => (
        Icons.cloud_off_outlined,
        l.syncStripOffline(n),
        p.ink,
        l.syncStripRetry,
      ),
      SyncState.failed => (
        Icons.error_outline,
        l.syncStripFailed(n),
        p.due,
        l.syncStripRetry,
      ),
    };

    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.base),
      curve: AppMotion.state,
      child: state == SyncState.synced
          ? const SizedBox(width: double.infinity)
          : Material(
              color: state == SyncState.failed
                  ? p.due.withValues(alpha: 0.08)
                  : p.surfaceMuted,
              child: Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.xs,
                    AppSpace.sm,
                    AppSpace.xs,
                  ),
                  child: Row(
                    spacing: AppSpace.sm,
                    children: [
                      Icon(icon, size: 18, color: tone),
                      Expanded(
                        child: Text(
                          label,
                          style: text.bodySmall?.copyWith(color: tone),
                        ),
                      ),
                      if (action != null)
                        TextButton(
                          onPressed: () {
                            final s = ref.read(syncServiceProvider);
                            state == SyncState.failed
                                ? s.retryFailed()
                                : s.kick();
                          },
                          child: Text(action),
                        )
                      else
                        const SizedBox(height: AppSize.touch),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
