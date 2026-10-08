import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/db.dart';
import '../../../core/errors.dart';
import '../domain/member.dart';
import '../domain/mess.dart';

class MessRepository {
  MessRepository(this._client, this._db);

  final SupabaseClient _client;
  final AppDb _db;

  /// My memberships (pending, active, inactive), oldest first. Cached for
  /// offline start.
  Future<List<Membership>> myMemberships() => guard(() async {
    final uid =
        _client.auth.currentUser?.id ??
        (throw const AppFailure(FailureKind.notAuthenticated));
    final rows = await _db.cachedRows(
      'memberships:$uid',
      () => _client
          .from('mess_members')
          .select('*, messes(*)')
          .eq('user_id', uid)
          .neq('status', MemberStatus.left.name)
          .order('created_at'),
    );
    return rows.map(Membership.fromJson).toList();
  });

  /// Returns the new mess id; the caller becomes its manager.
  Future<String> createMess({
    required String name,
    required String displayName,
    int monthStartDay = 1,
  }) => guard(() async {
    final id = await _client.rpc(
      'create_mess',
      params: {
        'p_name': name.trim(),
        'p_display_name': displayName.trim(),
        'p_month_start_day': monthStartDay,
      },
    );
    return id as String;
  });

  /// Returns a fresh 6-character code (valid 7 days).
  Future<String> createInvite(String messId) => guard(() async {
    final code = await _client.rpc('create_invite', params: {'p_mess': messId});
    return code as String;
  });

  /// Returns my (pending) member id.
  Future<String> joinMess({
    required String code,
    required String displayName,
  }) => guard(() async {
    final id = await _client.rpc(
      'join_mess',
      params: {'p_code': code.trim(), 'p_display_name': displayName.trim()},
    );
    return id as String;
  });

  /// All members including pending and left, by join date.
  Future<List<Member>> members(String messId) => guard(() async {
    final rows = await _db.cachedRows(
      'members:$messId',
      () => _client
          .from('mess_members')
          .select()
          .eq('mess_id', messId)
          .order('joined_on')
          .order('display_name'),
    );
    return rows.map(Member.fromJson).toList();
  });

  /// A member without an app account.
  Future<Member> addOfflineMember({
    required String messId,
    required String displayName,
    String? room,
  }) => guard(() async {
    final row = await _client
        .from('mess_members')
        .insert({
          'mess_id': messId,
          'display_name': displayName.trim(),
          'room': ?_blankToNull(room),
        })
        .select()
        .single();
    return Member.fromJson(row);
  });

  Future<Member> approveMember(String memberId) => _updateMember(memberId, {
    'status': MemberStatus.active.name,
    'joined_on': _today(),
  });

  /// Deletes a pending request.
  Future<void> rejectMember(String memberId) => guard(() async {
    final rows = await _client
        .from('mess_members')
        .delete()
        .eq('id', memberId)
        .eq('status', MemberStatus.pending.name)
        .select();
    requireRows(rows);
  });

  Future<Member> setRole(String memberId, MemberRole role) =>
      _updateMember(memberId, {'role': role.name});

  /// `left` stamps `left_on` today; any other status clears it.
  Future<Member> setStatus(String memberId, MemberStatus status) =>
      _updateMember(memberId, {
        'status': status.name,
        'left_on': status == MemberStatus.left ? _today() : null,
      });

  /// Only non-null fields are changed.
  Future<Mess> updateMess(
    String messId, {
    String? name,
    String? address,
    int? monthStartDay,
    String? mealOffCutoff,
  }) => guard(() async {
    final rows = await _client
        .from('messes')
        .update({
          'name': ?name?.trim(),
          'address': ?address?.trim(),
          'month_start_day': ?monthStartDay,
          'meal_off_cutoff': ?mealOffCutoff,
        })
        .eq('id', messId)
        .select();
    return Mess.fromJson(requireRows(rows).first);
  });

  Future<Member> _updateMember(String id, Map<String, Object?> values) =>
      guard(() async {
        final rows = await _client
            .from('mess_members')
            .update(values)
            .eq('id', id)
            .select();
        return Member.fromJson(requireRows(rows).first);
      });
}

String? _blankToNull(String? s) =>
    (s == null || s.trim().isEmpty) ? null : s.trim();

/// Local calendar date as 'yyyy-MM-dd'.
String _today() => DateTime.now().toIso8601String().substring(0, 10);
