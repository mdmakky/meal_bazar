import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../money/presentation/money_sheets.dart' show shortDate;
import '../application/notice_providers.dart';
import '../domain/notice.dart';

/// Home's notices (see [homeNotices]): at most [max] cards, then a link to
/// the board. Nothing when there are none. Tap opens the notice.
class HomeNotices extends ConsumerWidget {
  const HomeNotices({super.key});

  static const max = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.featureOn('notices')) return const SizedBox.shrink();
    final all = ref.watch(homeNoticesProvider);
    final l = AppLocalizations.of(context);
    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.base),
      curve: AppMotion.state,
      alignment: Alignment.topCenter,
      child: all.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.md,
                AppSpace.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.sm,
                children: [
                  for (final n in all.take(max))
                    _NoticeCard(key: ValueKey(n.id), notice: n),
                  if (all.length > max)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => context.push('/more/notices'),
                        child: Text(l.homeNoticeAll),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({super.key, required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final n = notice;
    final unread = !n.isRead;
    final meta = [
      if (n.pinned) l.noticePinned,
      // Expires at the start of the day after the last day shown.
      if (n.expiresAt != null)
        l.noticeUntil(
          shortDate(
            context,
            n.expiresAt!.toLocal().subtract(const Duration(minutes: 1)),
          ),
        ),
    ].join(' · ');

    return Semantics(
      label: unread ? l.noticeUnread : null,
      child: AppCard.raised(
        onTap: () => context.push('/more/notices/${n.id}'),
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          spacing: AppSpace.md,
          children: [
            AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.base),
              curve: AppMotion.state,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: unread ? p.accentSoft : p.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                n.pinned ? Icons.push_pin_outlined : Icons.campaign_outlined,
                size: AppSize.spinner,
                color: unread ? p.ink : p.inkSecondary,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.xs / 2,
                children: [
                  Row(
                    spacing: AppSpace.sm,
                    children: [
                      Flexible(
                        child: Text(
                          n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            color: unread ? p.ink : p.inkSecondary,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: unread ? 1 : 0,
                        duration: AppMotion.of(context, AppMotion.base),
                        child: Container(
                          key: const Key('homeNoticeUnreadDot'),
                          width: AppSize.dot,
                          height: AppSize.dot,
                          decoration: BoxDecoration(
                            color: p.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (n.body.isNotEmpty)
                    Text(
                      n.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(color: p.inkSecondary),
                    ),
                  if (meta.isNotEmpty)
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(color: p.inkTertiary),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.inkTertiary),
          ],
        ),
      ),
    );
  }
}
