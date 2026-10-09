import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/message_repository.dart';
import '../domain/message.dart';
import '../domain/message_draft.dart';
import 'unread_provider.dart';

/// My visible threads in a mess, newest activity first.
final threadsProvider = FutureProvider.family<List<MessageThread>, String>(
  (ref, messId) => ref.watch(messageRepositoryProvider).threads(messId),
);

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

  /// Best effort: a failed read mark just leaves the dot on.
  Future<void> markRead(MessageThread t) async {
    try {
      await _repo.markRead(t.id);
      _ref
        ..invalidate(unreadMessagesCountProvider(t.messId))
        ..invalidate(threadsProvider(t.messId));
    } catch (_) {}
  }

  void _refresh(MessageThread t) => _ref
    ..invalidate(threadMessagesProvider(t.id))
    ..invalidate(threadProvider(t.id))
    ..invalidate(threadsProvider(t.messId));
}
