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

  /// Entries in `[from, to)`, optionally for one member, oldest first.
  Future<List<MealEntry>> entriesForRange(
    String messId,
    DateTime from,
    DateTime to, {
    String? memberId,
  }) => guard(() async {
    var q = _client
        .from('meal_entries')
        .select('member_id, meal_type_id, date, count, guest_count, is_off')
        .eq('mess_id', messId)
        .gte('date', isoDate(from))
        .lt('date', isoDate(to));
    if (memberId != null) q = q.eq('member_id', memberId);
    final rows = await q.order('date');
    return rows.map(MealEntry.fromJson).toList();
  });

  /// Guest meals per member in `[from, to)`, from SQL `member_meal_totals`.
  Future<Map<String, double>> guestMeals(
    String messId,
    DateTime from,
    DateTime to,
  ) => guard(() async {
    final rows =
        await _client.rpc(
              'member_meal_totals',
              params: {
                'p_mess': messId,
                'p_from': isoDate(from),
                'p_to': isoDate(to),
              },
            )
            as List;
    return {
      for (final r in rows.cast<Map<String, dynamic>>())
        r['member_id'] as String: (r['guest_meals'] as num).toDouble(),
    };
  });

  Future<void> createMealType(
    String messId, {
    required String name,
    required int sortOrder,
    double weight = 1,
  }) => guard(() async {
    final rows = await _client
        .from('meal_types')
        .insert({
          'mess_id': messId,
          'name': name.trim(),
          'sort_order': sortOrder,
          'weight': weight,
        })
        .select('id');
    requireRows(rows);
  });

  Future<void> updateMealType(
    String id, {
    String? name,
    double? weight,
    bool? enabled,
    int? sortOrder,
  }) => guard(() async {
    final rows = await _client
        .from('meal_types')
        .update({
          'name': ?name?.trim(),
          'weight': ?weight,
          'enabled': ?enabled,
          'sort_order': ?sortOrder,
        })
        .eq('id', id)
        .select('id');
    requireRows(rows);
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
