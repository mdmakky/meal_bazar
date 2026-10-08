import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';

part 'db.g.dart';

/// Local copy of `meal_entries`, one row per (member, date, meal type).
@DataClassName('LocalMeal')
class MealEntries extends Table {
  TextColumn get id => text()();
  TextColumn get messId => text()();
  TextColumn get memberId => text()();
  TextColumn get mealTypeId => text()();

  /// `yyyy-mm-dd`, so ranges compare as text.
  TextColumn get date => text()();
  RealColumn get count => real()();
  IntColumn get guestCount => integer()();
  BoolColumn get isOff => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {memberId, date, mealTypeId};
}

@DataClassName('LocalBazar')
class Bazars extends Table {
  TextColumn get id => text()();
  TextColumn get messId => text()();
  TextColumn get date => text()();
  RealColumn get amount => real()();
  TextColumn get buyerMemberId => text().nullable()();
  TextColumn get paidByMemberId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get source => text()();
  TextColumn get receiptPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalBazarItem')
class BazarItems extends Table {
  TextColumn get id => text()();
  TextColumn get bazarId => text()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  RealColumn get qty => real().nullable()();
  TextColumn get unit => text().nullable()();
  IntColumn get sort => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Read-only server rows (members, meal types, memberships, profile) kept as
/// JSON so screens render offline.
class JsonCache extends Table {
  TextColumn get key => text()();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Writes waiting for the server. [rowKey] identifies the row the op writes.
@DataClassName('SyncOp')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entity => text()();
  TextColumn get rowKey => text()();
  TextColumn get messId => text()();
  TextColumn get op => text().withDefault(const Constant('upsert'))();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// [opPending], [opSyncing] or [opFailed].
  TextColumn get status => text().withDefault(const Constant(opPending))();

  /// A [FailureKind] name.
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

const opPending = 'pending';
const opSyncing = 'syncing';
const opFailed = 'failed';

@DriftDatabase(tables: [MealEntries, Bazars, BazarItems, JsonCache, SyncQueue])
class AppDb extends _$AppDb {
  AppDb(super.e);

  @override
  int get schemaVersion => 1;

  /// Fetches [fetch] and caches it; on a network failure returns the cache.
  Future<List<Map<String, dynamic>>> cachedRows(
    String key,
    Future<List<Map<String, dynamic>>> Function() fetch,
  ) async {
    try {
      final rows = await guard(fetch);
      await into(jsonCache).insertOnConflictUpdate(
        JsonCacheCompanion.insert(key: key, json: jsonEncode(rows)),
      );
      return rows;
    } on AppFailure catch (e) {
      if (e.kind != FailureKind.network) rethrow;
      final hit = await (select(
        jsonCache,
      )..where((c) => c.key.equals(key))).getSingleOrNull();
      if (hit == null) rethrow;
      return (jsonDecode(hit.json) as List).cast<Map<String, dynamic>>();
    }
  }

  /// Queues an upsert; it replaces any not-yet-sent op for the same row, so
  /// only the latest value is pushed. Call inside the row's transaction.
  Future<void> enqueue(
    String entity,
    String rowKey,
    String id,
    Map<String, dynamic> payload,
  ) async {
    await (delete(syncQueue)..where(
          (q) =>
              q.entity.equals(entity) &
              q.rowKey.equals(rowKey) &
              q.status.equals(opSyncing).not(),
        ))
        .go();
    await into(syncQueue).insert(
      SyncQueueCompanion.insert(
        id: id,
        entity: entity,
        rowKey: rowKey,
        messId: payload['mess_id'] as String,
        payload: jsonEncode(payload),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Ops for [entity] by row key.
  Future<Map<String, SyncOp>> opsFor(String entity) async => {
    for (final o in await (select(
      syncQueue,
    )..where((q) => q.entity.equals(entity))).get())
      o.rowKey: o,
  };

  Future<SyncOp?> nextPending() =>
      (select(syncQueue)
            ..where((q) => q.status.equals(opPending))
            ..orderBy([(q) => OrderingTerm.asc(q.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> updateOp(
    String id, {
    required String status,
    int? attempts,
    String? lastError,
  }) => (update(syncQueue)..where((q) => q.id.equals(id))).write(
    SyncQueueCompanion(
      status: Value(status),
      attempts: Value.absentIfNull(attempts),
      lastError: Value(lastError),
    ),
  );

  Future<void> deleteOp(String id) =>
      (delete(syncQueue)..where((q) => q.id.equals(id))).go();

  /// Moves [from] ops back to pending (failed → retry; syncing → after a kill).
  Future<void> requeue(String from) =>
      (update(syncQueue)..where((q) => q.status.equals(from))).write(
        SyncQueueCompanion(
          status: const Value(opPending),
          attempts: from == opFailed ? const Value(0) : const Value.absent(),
          lastError: const Value(null),
        ),
      );

  Stream<List<SyncOp>> watchQueue() => select(syncQueue).watch();

  /// Drops failed ops; the next pull restores those rows from the server.
  Future<void> discard(Iterable<String> ids) => (delete(
    syncQueue,
  )..where((q) => q.id.isIn(ids) & q.status.equals(opFailed))).go();

  Future<int> unsentCount() async => (await select(syncQueue).get()).length;

  /// Local data belongs to one signed-in user. Signed out ([uid] null) or a
  /// different user: everything, unsent writes included, is wiped.
  Future<void> claimFor(String? uid) => transaction(() async {
    const key = 'owner';
    final owner = await (select(
      jsonCache,
    )..where((c) => c.key.equals(key))).getSingleOrNull();
    if (uid != null && owner?.json == uid) return;
    for (final t in allTables) {
      await delete(t).go();
    }
    if (uid != null) {
      await into(
        jsonCache,
      ).insert(JsonCacheCompanion.insert(key: key, json: uid));
    }
  });
}

/// Overridden with `AppDb(NativeDatabase.memory())` in tests.
final appDbProvider = Provider<AppDb>((ref) {
  final db = AppDb(driftDatabase(name: 'meal_bazar'));
  ref.onDispose(db.close);
  return db;
});
