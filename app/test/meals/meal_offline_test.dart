import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meal_bazar/core/db/db.dart';
import 'package:meal_bazar/core/db/sync.dart';
import 'package:meal_bazar/core/widgets/sync_badge.dart';
import 'package:meal_bazar/features/meals/data/meal_repository.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// No network at all: every request fails like airplane mode.
SupabaseClient offlineClient() => SupabaseClient(
  'http://localhost',
  'anon',
  httpClient: MockClient((_) async => throw const SocketException('offline')),
);

/// Answers every GET with [rows].
SupabaseClient serverWith(List<Map<String, dynamic>> rows) => SupabaseClient(
  'http://localhost',
  'anon',
  httpClient: MockClient(
    (req) async => http.Response(
      jsonEncode(rows),
      200,
      headers: {'content-type': 'application/json'},
      request: req,
    ),
  ),
);

final day = DateTime(2026, 10, 8);
final entry = MealEntry(
  memberId: 'm1',
  mealTypeId: 'lunch',
  date: day,
  count: 0.5,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDb db;
  late SyncService sync;

  setUp(() {
    db = AppDb(NativeDatabase.memory());
    sync = SyncService(db, (_, p) async {
      throw const SocketException('offline');
    });
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  Map<String, dynamic> serverRow(double count, DateTime updatedAt) => {
    'id': 'srv1',
    'member_id': 'm1',
    'meal_type_id': 'lunch',
    'date': '2026-10-08',
    'count': count,
    'guest_count': 0,
    'is_off': false,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  test('offline save lands in Drift and the queue; reads come back', () async {
    final repo = MealRepository(offlineClient(), db, sync);
    await repo.save('mess1', entry);

    final list = await repo.entriesForDay('mess1', day);
    expect(list.single.count, 0.5);
    final op = (await db.select(db.syncQueue).get()).single;
    expect(opState(op), SyncState.offline);
    expect(jsonDecode(op.payload), containsPair('count', 0.5));
  });

  test('pull keeps an unsent local write over an older server row', () async {
    await MealRepository(offlineClient(), db, sync).save('mess1', entry);
    final old = DateTime.now().subtract(const Duration(hours: 1));
    final list = await MealRepository(
      serverWith([serverRow(1, old)]),
      db,
      sync,
    ).entriesForDay('mess1', day);
    expect(list.single.count, 0.5);
    expect(await db.select(db.syncQueue).get(), hasLength(1));
  });

  test('a newer server row wins and drops the unsent write', () async {
    await MealRepository(offlineClient(), db, sync).save('mess1', entry);
    final later = DateTime.now().add(const Duration(minutes: 5));
    final list = await MealRepository(
      serverWith([serverRow(1.5, later)]),
      db,
      sync,
    ).entriesForDay('mess1', day);
    expect(list.single.count, 1.5);
    expect(await db.select(db.syncQueue).get(), isEmpty);
  });

  test('synced rows deleted on the server disappear on pull', () async {
    final repo = MealRepository(serverWith([]), db, sync);
    await db
        .into(db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            id: 'x',
            messId: 'mess1',
            memberId: 'm2',
            mealTypeId: 'lunch',
            date: '2026-10-08',
            count: 1,
            guestCount: 0,
            isOff: false,
            updatedAt: DateTime.now(),
          ),
        );
    expect(await repo.entriesForDay('mess1', day), isEmpty);
  });

  test('meal types come in sort_order, ascending', () async {
    Map<String, dynamic> row(String id, String name, int order) => {
      'id': id,
      'mess_id': 'mess1',
      'name': name,
      'sort_order': order,
      'weight': 1,
      'enabled': true,
    };
    Uri? asked;
    // A server (or an old cache) answering in the wrong order.
    final client = SupabaseClient(
      'http://localhost',
      'anon',
      httpClient: MockClient((req) async {
        asked = req.url;
        return http.Response(
          jsonEncode([
            row('dinner', 'রাত', 2),
            row('lunch', 'দুপুর', 1),
            row('breakfast', 'সকাল', 0),
          ]),
          200,
          headers: {'content-type': 'application/json'},
          request: req,
        );
      }),
    );
    final repo = MealRepository(client, db, sync);
    final types = await repo.mealTypes('mess1');
    expect([for (final t in types) t.name], ['সকাল', 'দুপুর', 'রাত']);
    expect(asked!.queryParameters['order'], startsWith('sort_order.asc'));
  });
}
