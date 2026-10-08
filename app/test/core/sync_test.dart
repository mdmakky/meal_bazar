import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/db/db.dart';
import 'package:meal_bazar/core/db/sync.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/widgets/sync_badge.dart';

/// A server table keyed like `meal_entries` (member, date, meal type).
class FakeRemote {
  final rows = <String, Map<String, dynamic>>{};
  var calls = 0;

  /// Thrown before the write lands, unless [lostReply]: then after it, like a
  /// response lost on a flaky network.
  Object? error;
  var lostReply = false;

  Future<void> push(String entity, Map<String, dynamic> p) async {
    calls++;
    if (error != null && !lostReply) throw error!;
    rows['${p['member_id']}|${p['date']}|${p['meal_type_id']}'] = p;
    if (error != null) throw error!;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDb db;
  late FakeRemote remote;
  late SyncService sync;

  Future<void> enqueue(String opId, {double count = 1}) =>
      db.enqueue('meal_entries', 'm1|2026-10-08|lunch', opId, {
        'member_id': 'm1',
        'date': '2026-10-08',
        'meal_type_id': 'lunch',
        'count': count,
      });

  Future<List<SyncOp>> queue() => db.select(db.syncQueue).get();

  setUp(() {
    db = AppDb(NativeDatabase.memory());
    remote = FakeRemote();
    sync = SyncService(db, remote.push, maxAttempts: 2);
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  test('success: pushed once and dequeued', () async {
    await enqueue('op1');
    expect(queueState(await queue()), SyncState.syncing);
    await sync.drain();
    expect(remote.calls, 1);
    expect(remote.rows.values.single['count'], 1);
    expect(await queue(), isEmpty);
  });

  test('network failure parks the op as offline, then retries', () async {
    await enqueue('op1');
    remote.error = const SocketException('no route');
    await sync.drain();
    final op = (await queue()).single;
    expect((op.status, op.attempts, op.lastError), (opPending, 0, 'network'));
    expect(opState(op), SyncState.offline);

    remote.error = null;
    await sync.drain();
    expect(await queue(), isEmpty);
    expect(remote.rows, hasLength(1));
  });

  test('server refusal fails at once and is not retried', () async {
    await enqueue('op1');
    remote.error = const AppFailure(FailureKind.monthClosed);
    await sync.drain();
    var op = (await queue()).single;
    expect((op.status, op.lastError), (opFailed, 'monthClosed'));
    expect(queueState([op]), SyncState.failed);

    await sync.drain();
    expect(remote.calls, 1);

    // Retry is explicit.
    remote.error = null;
    await sync.retryFailed();
    expect(await queue(), isEmpty);
    expect(remote.calls, 2);
  });

  test('unexplained errors fail after the attempt cap', () async {
    await enqueue('op1');
    remote.error = Exception('500');
    await sync.drain();
    var op = (await queue()).single;
    expect((op.status, op.attempts), (opPending, 1));
    await sync.drain();
    op = (await queue()).single;
    expect((op.status, op.attempts), (opFailed, 2));
    await sync.drain();
    expect(remote.calls, 2);
  });

  test('retry after a lost reply leaves a single server row', () async {
    await enqueue('op1');
    remote
      ..error = const SocketException('reset')
      ..lostReply = true;
    await sync.drain();
    expect(remote.rows, hasLength(1));

    remote.error = null;
    await sync.drain();
    expect(remote.calls, 2);
    expect(remote.rows, hasLength(1));
    expect(await queue(), isEmpty);
  });

  test('a newer write to the same row replaces the unsent one', () async {
    await enqueue('op1');
    await enqueue('op2', count: 0.5);
    expect(await queue(), hasLength(1));
    await sync.drain();
    expect(remote.calls, 1);
    expect(remote.rows.values.single['count'], 0.5);
  });

  test('cachedRows answers from cache only on network failure', () async {
    final rows = await db.cachedRows(
      'k',
      () async => [
        {'id': 'a'},
      ],
    );
    expect(rows.single['id'], 'a');
    final cached = await db.cachedRows(
      'k',
      () async => throw const SocketException('offline'),
    );
    expect(cached.single['id'], 'a');
    await expectLater(
      db.cachedRows('k', () async => throw Exception('500')),
      throwsA(isA<AppFailure>()),
    );
  });
}
