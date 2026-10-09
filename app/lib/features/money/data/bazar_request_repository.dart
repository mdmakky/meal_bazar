import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors.dart';
import '../domain/bazar_request.dart';

/// Online only: a request is waiting on a person, not money yet. Writes go
/// through the 0026 RPCs (RLS allows no direct writes).
class BazarRequestRepository {
  BazarRequestRepository(this._client);

  final SupabaseClient _client;

  /// [memberId]'s requests, newest first (the last 30).
  Future<List<BazarRequest>> mine(String messId, String memberId) =>
      guard(() async {
        final rows = await _client
            .from('bazar_requests')
            .select()
            .eq('mess_id', messId)
            .eq('member_id', memberId)
            .order('created_at', ascending: false)
            .limit(30);
        return rows.map(BazarRequest.fromJson).toList();
      });

  /// Every pending request in the mess, oldest bazar first (manager).
  Future<List<BazarRequest>> pending(String messId) => guard(() async {
    final rows = await _client
        .from('bazar_requests')
        .select()
        .eq('mess_id', messId)
        .eq('status', 'pending')
        .order('date', ascending: true)
        .order('created_at', ascending: true);
    return rows.map(BazarRequest.fromJson).toList();
  });

  /// Idempotent on [BazarRequest.id], so a retry never doubles.
  Future<void> submit(BazarRequest r) =>
      guard(() => _client.rpc('submit_bazar_request', params: r.params()));

  Future<void> cancel(String id) =>
      guard(() => _client.rpc('cancel_bazar_request', params: {'p_id': id}));

  /// Approve → the real bazar (same id); reject keeps [reason].
  Future<void> review(String id, {required bool approve, String? reason}) =>
      guard(
        () => _client.rpc(
          'review_bazar_request',
          params: {
            'p_id': id,
            'p_approve': approve,
            'p_reason': reason?.trim().isEmpty ?? true ? null : reason!.trim(),
          },
        ),
      );
}
