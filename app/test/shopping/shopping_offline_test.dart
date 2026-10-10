import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/db/db.dart';
import 'package:meal_bazar/core/db/sync.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/features/shopping/data/shopping_repository.dart';
import 'package:meal_bazar/features/shopping/domain/shopping.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockClient extends Mock implements SupabaseClient {}

ShoppingList sample() => ShoppingList(
  id: 'l1',
  messId: 'mess1',
  createdBy: 'm-boss',
  assigneeId: 'm-rahim',
  date: DateTime(2026, 10, 10),
  status: 'open',
  items: const [
    ShoppingItem(
      id: 'i1',
      listId: 'l1',
      name: 'চাল',
      qty: 5,
      unit: 'কেজি',
      sort: 1,
    ),
    ShoppingItem(id: 'i2', listId: 'l1', name: 'ডিম', sort: 2),
  ],
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDb db;
  late ShoppingRepository repo;
  late SyncService sync;
  final pushed = <String>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDb(NativeDatabase.memory());
    pushed.clear();
    // No network: every send fails the way a dead connection does.
    sync = SyncService(db, (entity, p) async {
      pushed.add(entity);
      throw const SocketException('offline');
    });
    final client = MockClient();
    when(() => client.from(any())).thenThrow(const SocketException('offline'));
    when(
      () => client.rpc(any(), params: any(named: 'params')),
    ).thenThrow(const SocketException('offline'));
    repo = ShoppingRepository(client, db, sync);
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  test(
    'offline: the list comes from the phone, with unsent edits on top',
    () async {
      await repo.remember(sample());
      await repo.upsertItem(
        'mess1',
        sample().items.first.copyWith(bought: true, price: 600),
      );
      // The edit is queued, not lost.
      expect((await db.opsFor('shopping_items')).keys, ['i1']);
      expect(pushed, isNotEmpty);

      final l = (await repo.list('mess1', 'l1'))!;
      expect(l.items.firstWhere((i) => i.id == 'i1').price, 600);
      expect(l.items.firstWhere((i) => i.id == 'i1').bought, isTrue);
      expect(l.total, 600);

      final all = await repo.lists('mess1');
      expect(all.single.items.first.price, 600);
    },
  );

  test(
    'a deleted item stays deleted while offline; its queued edit is dropped',
    () async {
      await repo.remember(sample());
      await repo.upsertItem('mess1', sample().items.first.copyWith(price: 10));
      await repo.deleteItem('mess1', 'i1');
      expect(await db.opsFor('shopping_items'), isEmpty);
      expect((await db.opsFor('shopping_item_delete')).keys, ['i1']);
      final l = (await repo.list('mess1', 'l1'))!;
      expect(l.items.map((i) => i.id), ['i2']);
    },
  );

  test(
    'sending as a bazar needs the network and every edit already sent',
    () async {
      await repo.remember(sample());
      await repo.upsertItem(
        'mess1',
        sample().items.first.copyWith(price: 600, bought: true),
      );
      await expectLater(
        repo.submit(sample(), ownPocket: true),
        throwsA(
          isA<AppFailure>().having((e) => e.kind, 'kind', FailureKind.network),
        ),
      );
    },
  );
}
