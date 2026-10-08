import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';

enum SyncState { synced, syncing, offline, failed }

/// Dot + label. Offline is calm (hollow dot, never red); failed offers retry.
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.state, this.onRetry});

  final SyncState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final style = Theme.of(context).textTheme.labelSmall;
    final (label, dot) = switch (state) {
      SyncState.synced => (l.syncSynced, null),
      SyncState.syncing => (l.syncSyncing, _PulseDot(color: p.accent)),
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

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: AppMotion.pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
    child: _Dot(color: widget.color),
  );
}
