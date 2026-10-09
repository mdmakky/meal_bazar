import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../application/notice_providers.dart';

/// The newest unread pinned notice; nothing when there is none.
/// Padded for the Home screen. Tap opens the notice (which marks it read and hides the banner).
class LatestNoticeBanner extends ConsumerWidget {
  const LatestNoticeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.featureOn('notices')) return const SizedBox.shrink();
    final n = ref.watch(latestPinnedUnreadProvider);
    if (n == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        0,
      ),
      child: Semantics(
        label: AppLocalizations.of(context).noticePinned,
        child: AppCard.raised(
          onTap: () => context.push('/more/notices/${n.id}'),
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            spacing: AppSpace.md,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: p.accentSoft,
                child: Icon(Icons.push_pin_outlined, size: 20, color: p.ink),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.xs,
                  children: [
                    Text(
                      n.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    if (n.body.isNotEmpty)
                      Text(
                        n.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(color: p.inkSecondary),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
