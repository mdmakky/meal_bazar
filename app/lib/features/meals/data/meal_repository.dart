import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dates.dart';
import '../../../core/errors.dart';
import '../domain/meal.dart';

class MealRepository {
  MealRepository(this._client);

  final SupabaseClient _client;

  Future<List<MealType>> mealTypes(String messId) => guard(() async {
    final rows = await _client
        .from('meal_types')
        .select()
        .eq('mess_id', messId)
        .order('sort_order');
    return rows.map(MealType.fromJson).toList();
  });

  Future<List<MealEntry>> entriesForDay(String messId, DateTime day) =>
      guard(() async {
        final rows = await _client
            .from('meal_entries')
            .select('member_id, meal_type_id, date, count, guest_count, is_off')
            .eq('mess_id', messId)
            .eq('date', isoDate(day));
        return rows.map(MealEntry.fromJson).toList();
      });

  /// Idempotent: keyed on (member, date, meal type), so retries never duplicate.
  Future<void> save(String messId, MealEntry e, {String source = 'app'}) =>
      guard(() async {
        final rows = await _client
            .from('meal_entries')
            .upsert({
              'mess_id': messId,
              'member_id': e.memberId,
              'meal_type_id': e.mealTypeId,
              'date': isoDate(e.date),
              'count': e.count,
              'guest_count': e.guestCount,
              'is_off': e.isOff,
              'source': source,
            }, onConflict: 'member_id,date,meal_type_id')
            .select('id');
        requireRows(rows);
      });

  /// Creates missing rows for active members (copy of yesterday, else 1).
  Future<int> fillDay(String messId, DateTime day) => guard(() async {
    final n = await _client.rpc(
      'fill_meals_for_day',
      params: {'p_mess': messId, 'p_date': isoDate(day)},
    );
    return n as int;
  });
}
