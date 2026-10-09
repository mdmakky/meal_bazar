import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/db.dart';
import '../../../core/errors.dart';
import '../../../core/supabase.dart';
import '../domain/message.dart';

final messageRepositoryProvider = Provider<MessageRepository>(
  (ref) => MessageRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDbProvider),
  ),
);

/// RLS: a member sees their own threads, managers every thread of the mess.
/// Writes go through RPCs with client ids, so a retry never duplicates.
/// Lists are cached for offline reading; sending needs the network.
class MessageRepository {
  MessageRepository(this._client, this._db);

  final SupabaseClient _client;
  final AppDb _db;

  String? get myUserId => _client.auth.currentUser?.id;

  Future<List<MessageThread>> threads(String messId) => guard(() async {
    final rows = await _db.cachedRows(
      'message_threads:$messId',
      () => _client
          .from('message_thread_feed')
          .select()
          .eq('mess_id', messId)
          .order('last_message_at', ascending: false),
    );
    return rows.map(MessageThread.fromJson).toList();
  });

  Future<MessageThread?> thread(String id) => guard(() async {
    final rows = await _db.cachedRows(
      'message_thread:$id',
      () => _client.from('message_thread_feed').select().eq('id', id),
    );
    return rows.map(MessageThread.fromJson).firstOrNull;
  });

  Future<List<ChatMessage>> messages(String threadId) => guard(() async {
    final rows = await _db.cachedRows(
      'messages:$threadId',
      () => _client
          .from('messages')
          .select('id, thread_id, sender_id, body, created_at, hidden_at')
          .eq('thread_id', threadId)
          .order('created_at'),
    );
    return rows.map(ChatMessage.fromJson).toList();
  });

  /// [memberId] (manager only) writes to that member instead of as myself.
  Future<void> startThread({
    required String id,
    required String messageId,
    required String messId,
    required String subject,
    required String body,
    String? memberId,
    String? refType,
    String? refId,
    String? refLabel,
  }) => guard(
    () => _client.rpc<void>(
      'start_thread',
      params: {
        'p_id': id,
        'p_mess': messId,
        'p_subject': subject,
        'p_body': body,
        'p_ref_type': refType,
        'p_ref_id': refId,
        'p_ref_label': refLabel,
        'p_member': memberId,
        'p_message_id': messageId,
      },
    ),
  );

  Future<void> post(String id, String threadId, String body) => guard(
    () => _client.rpc<void>(
      'post_message',
      params: {'p_id': id, 'p_thread': threadId, 'p_body': body},
    ),
  );

  Future<void> setResolved(String threadId, bool resolved) => guard(
    () => _client.rpc<void>(
      'set_thread_status',
      params: {
        'p_thread': threadId,
        'p_status': resolved ? 'resolved' : 'open',
      },
    ),
  );

  Future<void> markRead(String threadId) => guard(
    () => _client.rpc<void>('mark_thread_read', params: {'p_thread': threadId}),
  );

  /// The mess group's thread id, created on first use. Offline, the cached
  /// inbox still knows it.
  Future<String> groupId(String messId) => guard(() async {
    try {
      final id = await _client.rpc(
        'ensure_mess_group',
        params: {'p_mess': messId},
      );
      return id as String;
    } catch (_) {
      final cached = (await threads(messId)).where((t) => t.isGroup);
      if (cached.isEmpty) rethrow;
      return cached.first.id;
    }
  });

  /// Removes a group message for everyone (managers: any; members: own).
  Future<void> hide(String messageId) => guard(
    () => _client.rpc<void>('hide_message', params: {'p_id': messageId}),
  );

  /// Direct threads with an unread message (group chatter is not counted).
  Future<int> unreadCount(String messId) => guard(() async {
    final n = await _client.rpc(
      'unread_thread_count',
      params: {'p_mess': messId},
    );
    return n as int;
  });
}
