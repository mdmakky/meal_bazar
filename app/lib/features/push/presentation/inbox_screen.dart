import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../meals/presentation/meal_grid.dart' show clockText;
import '../../mess/presentation/common.dart';
import '../../money/presentation/money_sheets.dart' show longDate, shortDate;
import '../application/inbox_providers.dart';
import '../domain/push.dart';
import 'push_screens.dart' show pushTypeCopy;

/// The Home app-bar bell: opens the inbox, badged with my unread count.
class InboxBell extends ConsumerWidget {
  const InboxBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Quiet while loading or offline: the bell works without a count.
    final n = ref.watch(inboxUnreadCountProvider).value ?? 0;
    return IconButton(
      key: const Key('inboxBell'),
      tooltip: AppLocalizations.of(context).inboxTitle,
      onPressed: () => context.push('/more/notifications/inbox'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(n > 0 ? Icons.notifications : Icons.notifications_none_outlined),
          PositionedDirectional(
            top: -AppSpace.sm,
            start: AppSpace.md,
            child: AnimatedScale(
              scale: n > 0 ? 1 : 0,
              duration: AppMotion.of(context, AppMotion.base),
              curve: AppMotion.arrive,
              child: CountBadge(n),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything the server told me (0026 `notifications`), by day, newest
/// first. Tap marks it read and opens its screen.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final inbox = ref.watch(inboxProvider);
    final hasUnread = inbox.value?.any((i) => !i.isRead) ?? false;

    Future<void> refresh() async {
      ref.invalidate(inboxUnreadCountProvider);
      await ref
          .refresh(inboxProvider.future)
          .catchError((_) => const <InboxItem>[]);
    }

    Future<void> markAll() async {
      try {
        await ref.read(inboxProvider.notifier).markAllRead();
      } catch (e) {
        if (context.mounted) showFailure(context, e);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.inboxTitle),
        actions: [
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.fast),
            child: hasUnread
                ? TextButton(
                    key: const Key('inboxMarkAll'),
                    onPressed: markAll,
                    child: Text(l.inboxMarkAllRead),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: AppSpace.sm),
        ],
      ),
      body: switch (inbox) {
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: refresh,
          child: value.isEmpty
              ? CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        icon: Icons.notifications_none_outlined,
                        message: l.inboxEmpty,
                      ),
                    ),
                  ],
                )
              : _InboxList(items: value),
        ),
        AsyncValue(:final error?) => ErrorView(
          message: failureText(context, error),
          onRetry: () => ref.invalidate(inboxProvider),
        ),
        _ => const LoadingView(rows: 6),
      },
    );
  }
}

class _InboxList extends ConsumerWidget {
  const _InboxList({required this.items});

  final List<InboxItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final now = today();

    String dayLabel(DateTime d) => switch (now.difference(d).inDays) {
      <= 0 => l.todayIsToday,
      1 => l.dayYesterday,
      _ => d.year == now.year ? shortDate(context, d) : longDate(context, d),
    };

    void open(InboxItem i) {
      unawaited(
        ref.read(inboxProvider.notifier).markRead(i).catchError((_) {}),
      );
      final route = i.route;
      if (route == null || !route.startsWith('/')) return;
      // Tab roots (/money, /bazar) switch tab; screens under More stack.
      route.startsWith('/more/') ? context.push(route) : context.go(route);
    }

    return StaggeredList(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpace.xxxl),
        children: StaggeredList.wrap([
          for (final (day, group) in inboxByDay(items)) ...[
            SectionTitle(dayLabel(day)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
              child: RaisedGroup(
                children: [
                  for (final i in group)
                    _InboxRow(
                      key: ValueKey(i.id),
                      item: i,
                      onTap: () => open(i),
                    ),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({super.key, required this.item, required this.onTap});

  final InboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final unread = !item.isRead;
    final t = item.pushType;
    final icon = t == null
        ? Icons.notifications_none_outlined
        : pushTypeCopy(l, t).$1;
    final d = AppMotion.of(context, AppMotion.base);

    return Semantics(
      label: unread ? l.inboxUnread : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            AppSpace.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.md,
            children: [
              IconTile(icon, color: unread ? p.ink : p.inkTertiary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.xs / 2,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.sm,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              color: unread ? p.ink : p.inkSecondary,
                            ),
                          ),
                        ),
                        Text(
                          clockText(
                            context,
                            item.createdAt.hour,
                            item.createdAt.minute,
                          ),
                          style: text.labelSmall?.copyWith(
                            color: p.inkTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (item.body.isNotEmpty)
                      Text(
                        item.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(color: p.inkSecondary),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: AnimatedOpacity(
                  opacity: unread ? 1 : 0,
                  duration: d,
                  child: Container(
                    key: ValueKey('inboxUnreadDot${item.id}'),
                    width: AppSize.dot,
                    height: AppSize.dot,
                    decoration: BoxDecoration(
                      color: p.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
