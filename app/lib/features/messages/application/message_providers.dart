import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/message_repository.dart';
import '../domain/message.dart';
import '../domain/message_draft.dart';
import '../../push/application/push_service.dart';
import 'unread_provider.dart';

/// My visible threads in a mess, newest activity first. The mess group is
/// created the first time the inbox loads without it (best effort).
final threadsProvider = FutureProvider.family<List<MessageThread>, String>((
  ref,
  messId,
) async {
  final repo = ref.watch(messageRepositoryProvider);
  final list = await repo.threads(messId);
  if (list.any((t) => t.isGroup)) return list;
  try {
    await repo.groupId(messId);
    return await repo.threads(messId);
  } catch (_) {
    return list;
  }
});

/// The mess group's thread id (Home shortcut, `/more/messages/group`).
final groupThreadIdProvider = FutureProvider.family<String, String>(
  (ref, messId) => ref.watch(messageRepositoryProvider).groupId(messId),
);

/// Unread direct threads and whether the group has unread messages, for the
/// Home shortcuts. Refreshes when a push arrives while the app is open.
final unreadSplitProvider =
    FutureProvider.family<({int direct, bool group}), String>((
      ref,
      messId,
    ) async {
      ref.watch(pushArrivalProvider);
      final list = await ref.watch(messageRepositoryProvider).threads(messId);
      return (
        direct: list.where((t) => !t.isGroup && t.isUnread).length,
        group: list.any((t) => t.isGroup && t.isUnread),
      );
    });

final threadProvider = FutureProvider.family<MessageThread?, String>(
  (ref, id) => ref.watch(messageRepositoryProvider).thread(id),
);

final threadMessagesProvider = FutureProvider.family<List<ChatMessage>, String>(
  (ref, threadId) => ref.watch(messageRepositoryProvider).messages(threadId),
);

final messageControllerProvider = Provider<MessageController>(
  MessageController.new,
);

/// Mutations. Each throws `AppFailure`; callers keep their draft on failure.
class MessageController {
  MessageController(this._ref);

  final Ref _ref;

  MessageRepository get _repo => _ref.read(messageRepositoryProvider);

  String? get myUserId => _repo.myUserId;

  /// Returns the new thread id. [threadId] is reused on retry.
  Future<String> start({
    required String threadId,
    required String messageId,
    required String messId,
    required String subject,
    required String body,
    String? memberId,
    MessageDraft? draft,
  }) async {
    await _repo.startThread(
      id: threadId,
      messageId: messageId,
      messId: messId,
      subject: subject.trim(),
      body: body.trim(),
      memberId: memberId,
      refType: draft?.refType,
      refId: draft?.refId,
      refLabel: draft?.refLabel,
    );
    _ref.invalidate(threadsProvider(messId));
    return threadId;
  }

  /// Sends (or re-sends, same [id]) and refreshes the thread.
  Future<void> post(MessageThread t, String id, String body) async {
    await _repo.post(id, t.id, body.trim());
    _refresh(t);
  }

  Future<void> setResolved(MessageThread t, bool resolved) async {
    await _repo.setResolved(t.id, resolved);
    _refresh(t);
  }

  /// Removes a group message for everyone.
  Future<void> hide(MessageThread t, String messageId) async {
    await _repo.hide(messageId);
    _refresh(t);
  }

  /// Best effort: a failed read mark just leaves the dot on.
  Future<void> markRead(MessageThread t) async {
    try {
      await _repo.markRead(t.id);
      _ref
        ..invalidate(unreadMessagesCountProvider(t.messId))
        ..invalidate(unreadSplitProvider(t.messId))
        ..invalidate(threadsProvider(t.messId));
    } catch (_) {}
  }

  void _refresh(MessageThread t) => _ref
    ..invalidate(threadMessagesProvider(t.id))
    ..invalidate(threadProvider(t.id))
    ..invalidate(threadsProvider(t.messId));
}
