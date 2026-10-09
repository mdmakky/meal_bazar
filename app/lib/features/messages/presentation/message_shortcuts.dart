import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../application/message_providers.dart';

/// Home, under the hero: two compact ways in. A member writes to the manager
/// (or reads the reply when one is unread); a manager opens the inbox. Both
/// open the mess group. Hidden by the `messages` / `mess_group` flags.
class MessageShortcuts extends ConsumerWidget {
  const MessageShortcuts({
    super.key,
    required this.messId,
    required this.manager,
  });

  final String messId;
  final bool manager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.featureOn('messages')) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final group = ref.featureOn('mess_group');
    // Quiet while loading or offline: the shortcuts work without counts.
    final unread = ref.watch(unreadSplitProvider(messId)).value;
    final direct = unread?.direct ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        0,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.sm,
          children: [
            Expanded(
              child: _Shortcut(
                key: const Key('homeMsgShortcut'),
                icon: manager ? Icons.forum_outlined : Icons.edit_outlined,
                label: manager ? l.msgTitle : l.homeMsgManager,
                count: direct,
                onTap: () => context.push(
                  manager || direct > 0
                      ? '/more/messages'
                      : '/more/messages/new',
                ),
              ),
            ),
            if (group)
              Expanded(
                child: _Shortcut(
                  key: const Key('homeGroupShortcut'),
                  icon: Icons.groups_outlined,
                  label: l.msgGroupShort,
                  dot: unread?.group ?? false,
                  onTap: () => context.push('/more/messages/group'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.count = 0,
    this.dot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Unread threads (a turmeric count pill) …
  final int count;

  /// … or just "something new" (a turmeric dot).
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final n = Fmt.digits('$count', bangla: l.localeName == 'bn');
    return Semantics(
      button: true,
      label: [
        label,
        if (count > 0) l.homeUnreadCount(n) else if (dot) l.msgUnread,
      ].join(', '),
      excludeSemantics: true,
      child: AppCard.raised(
        padding: const EdgeInsets.all(AppSpace.md),
        onTap: onTap,
        // Icon and mark on top, the label below with the card's full width,
        // so "ম্যানেজারকে বার্তা" survives 360dp at 1.3× text.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.xs + 2,
          children: [
            SizedBox(
              height: 24,
              child: Row(
                children: [
                  Icon(icon, size: 22, color: p.ink),
                  const Spacer(),
                  if (count > 0)
                    Container(
                      key: const Key('homeUnreadCount'),
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.xs + 2,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Text(
                        n,
                        textScaler: TextScaler.noScaling,
                        style: text.labelMedium?.copyWith(
                          // Dark ink on turmeric reads in both themes.
                          color: AppPalette.light.ink,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    )
                  else if (dot)
                    Container(
                      key: const Key('homeUnreadDot'),
                      width: AppSize.dot + 2,
                      height: AppSize.dot + 2,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
