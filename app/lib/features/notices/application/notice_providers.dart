import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ids.dart';
import '../../mess/application/mess_providers.dart';
import '../data/notice_repository.dart';
import '../domain/notice.dart';

/// Live notices for a mess: pinned first, newest first, expired dropped.
final noticesProvider = FutureProvider.family<List<Notice>, String>(
  (ref, messId) async => visibleNotices(
    await ref.watch(noticeRepositoryProvider).feed(messId),
    DateTime.now(),
  ),
);

/// Notices in the current mess (empty while loading or with no mess).
final currentNoticesProvider = Provider<List<Notice>>((ref) {
  final messId = ref.watch(currentMessIdProvider);
  if (messId == null) return const [];
  return ref.watch(noticesProvider(messId)).value ?? const [];
});

/// Unread count for the More tile badge.
final unreadNoticeCountProvider = Provider<int>(
  (ref) => ref.watch(currentNoticesProvider).where((n) => !n.isRead).length,
);

/// The newest unread pinned notice, for the Home banner.
final latestPinnedUnreadProvider = Provider<Notice?>(
  (ref) => ref
      .watch(currentNoticesProvider)
      .where((n) => n.pinned && !n.isRead)
      .firstOrNull,
);

final noticeControllerProvider = Provider<NoticeController>(
  NoticeController.new,
);

/// Mutations. Each throws `AppFailure` and refreshes the feed.
class NoticeController {
  NoticeController(this._ref);

  final Ref _ref;

  NoticeRepository get _repo => _ref.read(noticeRepositoryProvider);

  /// [id] null posts a new notice.
  Future<void> save({
    String? id,
    required String messId,
    required String title,
    required String body,
    required bool pinned,
    DateTime? expiresAt,
  }) async {
    await _repo.save(
      id: id ?? uuidV4(),
      messId: messId,
      title: title.trim(),
      body: body.trim(),
      pinned: pinned,
      expiresAt: expiresAt,
    );
    _ref.invalidate(noticesProvider(messId));
  }

  Future<void> delete(Notice n) async {
    await _repo.delete(n.id);
    _ref.invalidate(noticesProvider(n.messId));
  }

  /// No-op when already read or I have no membership here.
  Future<void> markRead(Notice n) async {
    final me = _ref.read(currentMembershipProvider)?.member;
    if (n.isRead || me == null || me.messId != n.messId) return;
    await _repo.markRead(n.id, me.id);
    _ref.invalidate(noticesProvider(n.messId));
  }
}
