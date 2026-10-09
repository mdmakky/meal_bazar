import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dates.dart';
import '../../../core/db/db.dart';
import '../../../core/db/sync.dart';
import '../../../core/errors.dart';
import '../../../core/ids.dart';
import '../domain/meal.dart';

/// [SyncQueue] row key of a meal entry: its natural key.
String mealRowKey(String memberId, String date, String mealTypeId) =>
    '$memberId|$date|$mealTypeId';

/// Entries are written to Drift first and synced through the queue. Reads
/// pull from Supabase when online and always answer from Drift.
class MealRepository {
  MealRepository(this._client, this._db, this._sync);

  final SupabaseClient _client;
  final AppDb _db;
  final SyncService _sync;

  Future<List<MealType>> mealTypes(String messId) => guard(() async {
    final rows = await _db.cachedRows(
      'meal_types:$messId',
      () => _client
          .from('meal_types')
          .select()
          .eq('mess_id', messId)
          // postgrest orders descending by default: say ascending.
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true)
          .retry(enabled: false),
    );
    // Rows cached before the fix may be reversed; columns follow sort_order.
    final types = rows.map(MealType.fromJson).toList();
    return [
      for (final (_, t)
          in types.indexed.toList()..sort(
            (a, b) => a.$2.sortOrder != b.$2.sortOrder
                ? a.$2.sortOrder.compareTo(b.$2.sortOrder)
                : a.$1.compareTo(b.$1),
          ))
        t,
    ];
  });

  /// Cells on [day] filled by the midnight job and not edited since
  /// (`source = 'auto'`, 0031), as `memberId|mealTypeId`. Online only.
  Future<Set<String>> autoFilledOnDay(String messId, DateTime day) =>
      guard(() async {
        final rows = await _client
            .from('meal_entries')
            .select('member_id, meal_type_id')
            .eq('mess_id', messId)
            .eq('date', isoDate(day))
            .eq('source', 'auto')
            .retry(enabled: false);
        return {for (final r in rows) '${r['member_id']}|${r['meal_type_id']}'};
      });

  Future<List<MealEntry>> entriesForDay(String messId, DateTime day) =>
      entriesForRange(messId, day, DateTime(day.year, day.month, day.day + 1));

  /// Entries in `[from, to)`, optionally for one member, oldest first.
  Future<List<MealEntry>> entriesForRange(
    String messId,
    DateTime from,
    DateTime to, {
    String? memberId,
  }) => guard(() async {
    try {
      final rows = await guard(() async {
        var q = _client
            .from('meal_entries')
            .select(
              'id, member_id, meal_type_id, date, count, guest_count, is_off, '
              'updated_at',
            )
            .eq('mess_id', messId)
            .gte('date', isoDate(from))
            .lt('date', isoDate(to));
        if (memberId != null) q = q.eq('member_id', memberId);
        // Offline answers from Drift at once instead of retrying for seconds.
        return await q.retry(enabled: false);
      });
      await _merge(messId, from, to, memberId, rows);
    } on AppFailure catch (e) {
      if (e.kind != FailureKind.network) rethrow;
    }
    return [
      for (final r in await _range(messId, from, to, memberId).get())
        MealEntry(
          memberId: r.memberId,
          mealTypeId: r.mealTypeId,
          date: DateTime.parse(r.date),
          count: r.count,
          guestCount: r.guestCount,
          isOff: r.isOff,
        ),
    ];
  });

  SimpleSelectStatement<$MealEntriesTable, LocalMeal> _range(
    String messId,
    DateTime from,
    DateTime to,
    String? memberId,
  ) => _db.select(_db.mealEntries)
    ..where(
      (t) =>
          t.messId.equals(messId) &
          t.date.isBiggerOrEqualValue(isoDate(from)) &
          t.date.isSmallerThanValue(isoDate(to)) &
          (memberId == null
              ? const Constant(true)
              : t.memberId.equals(memberId)),
    )
    ..orderBy([(t) => OrderingTerm.asc(t.date)]);

  /// Server rows replace local ones, except rows with a queued write: those
  /// keep the local value unless the server's is newer (last write wins).
  // ponytail: device vs server clock skew decides near-simultaneous edits.
  Future<void> _merge(
    String messId,
    DateTime from,
    DateTime to,
    String? memberId,
    List<Map<String, dynamic>> rows,
  ) => _db.transaction(() async {
    final ops = await _db.opsFor('meal_entries');
    final local = {
      for (final r in await _range(messId, from, to, memberId).get())
        mealRowKey(r.memberId, r.date, r.mealTypeId): r,
    };
    // Gone from the server (e.g. deleted elsewhere), unless still unsent.
    for (final MapEntry(:key, :value) in local.entries) {
      if (!ops.containsKey(key)) {
        await _db.delete(_db.mealEntries).delete(value);
      }
    }
    for (final r in rows) {
      final date = r['date'] as String;
      final key = mealRowKey(
        r['member_id'] as String,
        date,
        r['meal_type_id'] as String,
      );
      final theirs = DateTime.parse(r['updated_at'] as String);
      final op = ops[key];
      if (op != null) {
        final mine = local[key]?.updatedAt;
        if (op.status == opSyncing || (mine != null && !theirs.isAfter(mine))) {
          continue;
        }
        await _db.deleteOp(op.id);
      }
      await _db
          .into(_db.mealEntries)
          .insertOnConflictUpdate(
            MealEntriesCompanion.insert(
              id: r['id'] as String,
              messId: messId,
              memberId: r['member_id'] as String,
              mealTypeId: r['meal_type_id'] as String,
              date: date,
              count: (r['count'] as num).toDouble(),
              guestCount: r['guest_count'] as int,
              isOff: r['is_off'] as bool,
              updatedAt: theirs,
            ),
          );
    }
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
    String? serveTime,
  }) => guard(() async {
    final rows = await _client
        .from('meal_types')
        .update({
          'name': ?name?.trim(),
          'weight': ?weight,
          'enabled': ?enabled,
          'sort_order': ?sortOrder,
          'serve_time': ?serveTime,
        })
        .eq('id', id)
        .select('id');
    requireRows(rows);
  });

  /// Saves locally and queues an upsert keyed on (member, date, meal type),
  /// so retries never duplicate. Waits for one sync attempt; offline it
  /// returns at once and the write waits in the queue.
  Future<void> save(String messId, MealEntry e, {String source = 'app'}) =>
      saveAll(messId, [e], source: source);

  /// [save] for many entries: one transaction, one sync attempt.
  Future<void> saveAll(
    String messId,
    List<MealEntry> entries, {
    String source = 'app',
  }) => guard(() async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      for (final e in entries) {
        final date = isoDate(e.date);
        await _db
            .into(_db.mealEntries)
            .insert(
              MealEntriesCompanion.insert(
                id: uuidV4(),
                messId: messId,
                memberId: e.memberId,
                mealTypeId: e.mealTypeId,
                date: date,
                count: e.count,
                guestCount: e.guestCount,
                isOff: e.isOff,
                updatedAt: now,
              ),
              onConflict: DoUpdate(
                (_) => MealEntriesCompanion(
                  count: Value(e.count),
                  guestCount: Value(e.guestCount),
                  isOff: Value(e.isOff),
                  updatedAt: Value(now),
                ),
              ),
            );
        await _db.enqueue(
          'meal_entries',
          mealRowKey(e.memberId, date, e.mealTypeId),
          uuidV4(),
          {
            'mess_id': messId,
            'member_id': e.memberId,
            'meal_type_id': e.mealTypeId,
            'date': date,
            'count': e.count,
            'guest_count': e.guestCount,
            'is_off': e.isOff,
            'source': source,
          },
        );
      }
    });
    await _sync.drain();
  });

  /// Member self-service: switches my own meal off/on (SQL enforces cutoff).
  Future<void> setMyMealOff(
    String messId,
    DateTime date,
    String mealTypeId, {
    required bool off,
  }) => guard(
    () => _client.rpc(
      'set_my_meal_off',
      params: {
        'p_mess': messId,
        'p_date': isoDate(date),
        'p_meal_type': mealTypeId,
        'p_off': off,
      },
    ),
  );

  /// SQL `meal_off_deadlines`: each meal type's meal-off deadline on [day],
  /// by meal type id. Cached for offline.
  Future<Map<String, DateTime>> mealOffDeadlines(String messId, DateTime day) =>
      guard(() async {
        final rows = await _db.cachedRows(
          'meal_off_deadlines:$messId:${isoDate(day)}',
          () async => [
            for (final r in await _client.rpc(
              'meal_off_deadlines',
              params: {
                'p_mess': messId,
                'p_from': isoDate(day),
                'p_to': isoDate(day),
              },
            ))
              Map<String, dynamic>.from(r as Map),
          ],
        );
        return {
          for (final r in rows)
            if (r['deadline'] != null)
              r['meal_type_id'] as String: DateTime.parse(
                r['deadline'] as String,
              ),
        };
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
