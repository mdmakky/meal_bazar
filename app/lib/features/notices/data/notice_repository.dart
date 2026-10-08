import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors.dart';
import '../../../core/supabase.dart';
import '../domain/notice.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>(
  (ref) => NoticeRepository(ref.watch(supabaseClientProvider)),
);

/// RLS: members read, managers write, members mark only their own reads.
class NoticeRepository {
  NoticeRepository(this._client);

  final SupabaseClient _client;

  /// Live notices (not deleted, not expired) with my read flag.
  Future<List<Notice>> feed(String messId) => guard(() async {
    final rows = await _client
        .from('announcement_feed')
        .select()
        .eq('mess_id', messId);
    return rows.map(Notice.fromJson).toList();
  });

  /// Insert or edit; [id] is client-generated so a retry is idempotent.
  Future<void> save({
    required String id,
    required String messId,
    required String title,
    required String body,
    required bool pinned,
    DateTime? expiresAt,
  }) => guard(
    () => _client.from('announcements').upsert({
      'id': id,
      'mess_id': messId,
      'title': title,
      'body': body,
      'pinned': pinned,
      'expires_at': expiresAt?.toUtc().toIso8601String(),
    }),
  );

  Future<void> delete(String id) => guard(
    () => _client
        .from('announcements')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id),
  );

  Future<void> markRead(String noticeId, String memberId) => guard(
    () => _client.from('announcement_reads').upsert({
      'announcement_id': noticeId,
      'member_id': memberId,
    }, ignoreDuplicates: true),
  );
}
