import 'dart:async';

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
                  if (all.length == 1)
                    _NoticeCard(key: ValueKey(all.first.id), notice: all.first)
                  else
                    _NoticeCarousel(notices: all.take(max).toList()),
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

/// Several notices as one swipeable strip: the next card peeks in, it
/// advances by itself every few seconds (never with "Remove animations"),
/// and a touch hands control to the reader.
class _NoticeCarousel extends StatefulWidget {
  const _NoticeCarousel({required this.notices});

  final List<Notice> notices;

  @override
  State<_NoticeCarousel> createState() => _NoticeCarouselState();
}

class _NoticeCarouselState extends State<_NoticeCarousel> {
  static const _every = Duration(seconds: 5);
  static const _height = 116.0;

  // Endless: the strip only ever moves one way, wrapping past the last card.
  late final _pages = PageController(
    viewportFraction: 0.92,
    initialPage: widget.notices.length * 1000,
  );
  Timer? _timer;
  int _page = 0; // position in the list
  late int _raw = widget.notices.length * 1000; // position in the strip
  bool _touched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    if (_touched || AppMotion.reduced(context)) return;
    _timer = Timer(_every, () {
      if (!mounted || !_pages.hasClients) return;
      _pages.animateToPage(
        _raw + 1,
        duration: AppMotion.of(context, AppMotion.slow),
        curve: AppMotion.state,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = widget.notices.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        SizedBox(
          height: _height,
          child: Listener(
            onPointerDown: (_) {
              _touched = true;
              _timer?.cancel();
            },
            child: PageView.builder(
              key: const Key('noticeCarousel'),
              controller: _pages,
              padEnds: false,
              clipBehavior: Clip.none,
              onPageChanged: (i) {
                _raw = i;
                setState(() => _page = i % n);
                _arm();
              },
              itemBuilder: (_, i) {
                final notice = widget.notices[i % n];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
                  child: _NoticeCard(key: ValueKey(notice.id), notice: notice),
                );
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpace.xs,
          children: [
            for (var i = 0; i < n; i++)
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.base),
                curve: AppMotion.state,
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? p.accent : p.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
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
