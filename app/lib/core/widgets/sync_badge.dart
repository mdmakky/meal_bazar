import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../motion/effects.dart';
import '../theme/tokens.dart';

enum SyncState { synced, syncing, offline, failed }

/// Dot + label. Offline is calm (hollow dot, never red); failed offers retry
/// and discard (drop the local write, keep the server's value).
class SyncBadge extends StatelessWidget {
  const SyncBadge({
    super.key,
    required this.state,
    this.onRetry,
    this.onDiscard,
  });

  final SyncState state;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final style = Theme.of(context).textTheme.labelSmall;
    final (label, dot) = switch (state) {
      SyncState.synced => (l.syncSynced, null),
      SyncState.syncing => (l.syncSyncing, AnimatedSyncDot(color: p.accent)),
      SyncState.offline => (
        l.syncOffline,
        _Dot(border: Border.all(color: p.inkTertiary, width: 1.5)),
      ),
      SyncState.failed => (l.syncFailed, _Dot(color: p.warning)),
    };
    return Semantics(
      liveRegion: true,
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[dot, const SizedBox(width: AppSpace.sm)],
          ExcludeSemantics(child: Text(label, style: style)),
          if (state == SyncState.failed && onRetry != null) ...[
            const SizedBox(width: AppSpace.xs),
            TextButton(onPressed: onRetry, child: Text(l.retry)),
          ],
          if (state == SyncState.failed && onDiscard != null)
            TextButton(onPressed: onDiscard, child: Text(l.syncDiscard)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.color, this.border});

  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSize.dot,
    height: AppSize.dot,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: border,
    ),
  );
}
