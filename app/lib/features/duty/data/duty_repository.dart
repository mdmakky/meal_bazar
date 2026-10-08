import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dates.dart';
import '../../../core/errors.dart';
import '../../../core/supabase.dart';
import '../domain/duty.dart';

final dutyRepositoryProvider = Provider<DutyRepository>(
  (ref) => DutyRepository(ref.watch(supabaseClientProvider)),
);

/// Online only: the roster changes rarely and is not money.
class DutyRepository {
  DutyRepository(this._client);

  final SupabaseClient _client;

  /// Duties on [from]..[to] inclusive, by date.
  Future<List<BazarDuty>> duties(String messId, DateTime from, DateTime to) =>
      guard(() async {
        final rows = await _client
            .from('bazar_duties')
            .select()
            .eq('mess_id', messId)
            .gte('date', isoDate(from))
            .lte('date', isoDate(to))
            .order('date')
            .order('created_at');
        return rows.map(BazarDuty.fromJson).toList();
      });

  /// Returns how many duties were created.
  Future<int> generate(String messId, DutyRotation r) => guard(
    () async =>
        (await _client.rpc('generate_duty_rotation', params: r.params(messId))
                as num)
            .toInt(),
  );

  /// Manager insert/edit (RLS).
  Future<void> save(BazarDuty d) => guard(() async {
    requireRows(await _client.from('bazar_duties').upsert(d.toJson()).select());
  });

  Future<void> delete(String id) => guard(() async {
    requireRows(
      await _client.from('bazar_duties').delete().eq('id', id).select(),
    );
  });

  /// The assigned member marks their own duty (security definer RPC).
  Future<void> markMine(String id, bool done) => guard(
    () =>
        _client.rpc('mark_my_duty_done', params: {'p_id': id, 'p_done': done}),
  );
}
