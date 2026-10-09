import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/push.dart';
import 'push_service.dart';

/// My unread inbox count (the Home bell, the More row). Refreshes when a push
/// arrives in the foreground and when the app comes back to the front.
final inboxUnreadCountProvider = FutureProvider<int>((ref) async {
  ref.watch(pushArrivalProvider);
  final resume = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(resume.dispose);
  final uid = await ref.watch(authStateProvider.future);
  if (uid == null) return 0;
  return ref.watch(pushRepositoryProvider).unreadInboxCount();
});

/// My notification inbox, newest first.
final inboxProvider = AsyncNotifierProvider<InboxNotifier, List<InboxItem>>(
  InboxNotifier.new,
);

class InboxNotifier extends AsyncNotifier<List<InboxItem>> {
  @override
  Future<List<InboxItem>> build() async {
    ref.watch(pushArrivalProvider);
    final uid = await ref.watch(authStateProvider.future);
    if (uid == null) return const [];
    return ref.watch(pushRepositoryProvider).inbox();
  }

  /// Optimistic; on failure reloads the list and rethrows (AppFailure).
  Future<void> markRead(InboxItem item) =>
      _mark([item.id], (i) => i.id == item.id);

  Future<void> markAllRead() => _mark(null, (_) => true);

  Future<void> _mark(List<int>? ids, bool Function(InboxItem) hit) async {
    final items = state.value ?? const [];
    if (!items.any((i) => !i.isRead && hit(i))) return;
    state = AsyncData([for (final i in items) hit(i) ? i.read() : i]);
    try {
      await ref.read(pushRepositoryProvider).markInboxRead(ids);
    } catch (_) {
      if (ref.mounted) ref.invalidateSelf();
      rethrow;
    } finally {
      if (ref.mounted) ref.invalidate(inboxUnreadCountProvider);
    }
  }
}
