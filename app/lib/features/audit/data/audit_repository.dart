import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors.dart';
import '../../../core/supabase.dart';
import '../domain/audit.dart';

final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepository(ref.watch(supabaseClientProvider)),
);

class AuditRepository {
  AuditRepository(this._client);

  final SupabaseClient _client;

  /// Newest first. RLS limits reads to members of [messId].
  Future<List<AuditEntry>> page(
    String messId, {
    List<String>? entities,
    int offset = 0,
    int limit = 50,
  }) => guard(() async {
    var q = _client.from('audit_log').select().eq('mess_id', messId);
    if (entities != null) q = q.inFilter('entity', entities);
    final rows = await q
        .order('at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);
    return rows.map(AuditEntry.fromJson).toList();
  });

  /// What others recorded that concerns me, newest first (`my_activity`).
  Future<List<AuditEntry>> myActivity(String messId, {int limit = 30}) =>
      guard(() async {
        final rows =
            await _client.rpc(
                  'my_activity',
                  params: {'p_mess': messId, 'p_limit': limit},
                )
                as List;
        return [
          for (final r in rows) AuditEntry.fromJson(r as Map<String, dynamic>),
        ];
      });
}
