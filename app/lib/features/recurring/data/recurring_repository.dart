import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dates.dart';
import '../../../core/errors.dart';
import '../domain/recurring.dart';

/// Online only: these are occasional manager settings, not daily entry.
class RecurringRepository {
  RecurringRepository(this._client);

  final SupabaseClient _client;

  Future<List<RecurringExpense>> bills(String messId) => guard(() async {
    final rows = await _client
        .from('recurring_expenses')
        .select()
        .eq('mess_id', messId)
        .order('day_of_period', ascending: true)
        .order('created_at', ascending: true);
    return rows.map(RecurringExpense.fromJson).toList();
  });

  /// Upsert on the client id, so a retried save is idempotent.
  Future<void> saveBill(RecurringExpense b) => guard(() async {
    requireRows(
      await _client.from('recurring_expenses').upsert(b.toJson()).select('id'),
    );
  });

  /// Posts this period's bills (period containing [day]); returns how many.
  Future<int> apply(String messId, DateTime day) => guard(() async {
    final n = await _client.rpc(
      'apply_recurring_expenses',
      params: {'p_mess': messId, 'p_date': isoDate(day)},
    );
    return n as int;
  });

  /// Active bills not yet posted in the period containing [day].
  Future<int> pendingCount(String messId, DateTime day) => guard(() async {
    final n = await _client.rpc(
      'pending_recurring_count',
      params: {'p_mess': messId, 'p_date': isoDate(day)},
    );
    return n as int;
  });

  Future<Map<MealDefaultKey, double>> mealDefaults(String messId) =>
      guard(() async {
        final rows = await _client
            .from('meal_defaults')
            .select('member_id, meal_type_id, count')
            .eq('mess_id', messId);
        return {
          for (final r in rows)
            (
              memberId: r['member_id'] as String,
              mealTypeId: r['meal_type_id'] as String,
            ): double.parse(
              '${r['count']}',
            ),
        };
      });

  Future<void> setMealDefault(
    String messId,
    MealDefaultKey key,
    double count,
  ) => guard(() async {
    requireRows(
      await _client
          .from('meal_defaults')
          .upsert({
            'mess_id': messId,
            'member_id': key.memberId,
            'meal_type_id': key.mealTypeId,
            'count': count,
          })
          .select('member_id'),
    );
  });
}
