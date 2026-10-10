import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors.dart';
import '../supabase.dart';
import '../widgets/sync_badge.dart';
import 'db.dart';

/// Sends one queued op to the server. Must be idempotent.
typedef Push = Future<void> Function(String entity, Map<String, dynamic> p);

/// The server side of each queued entity: upserts on the client key, so a
/// retry after a lost response never duplicates a row.
Push supabasePush(SupabaseClient c) => (entity, p) async {
  switch (entity) {
    case 'meal_entries':
      requireRows(
        await c
            .from('meal_entries')
            .upsert(p, onConflict: 'member_id,date,meal_type_id')
            .select('id'),
      );
    case 'bazars':
      final items = p.remove('bazar_items') as List;
      // Ops queued before buyers existed have none: leave the server's alone.
      final buyers = p.remove('bazar_buyers') as List?;
      requireRows(await c.from('bazars').upsert(p).select('id'));
      await c.from('bazar_items').delete().eq('bazar_id', p['id'] as String);
      if (items.isNotEmpty) await c.from('bazar_items').insert(items);
      if (buyers != null) {
        await c.rpc(
          'set_bazar_buyers',
          params: {'p_bazar': p['id'], 'p_members': buyers},
        );
      }
    case 'shopping_items':
      p.remove('mess_id'); // queue bookkeeping, not a column
      requireRows(await c.from('shopping_items').upsert(p).select('id'));
    case 'shopping_item_delete':
      await c.from('shopping_items').delete().eq('id', p['id'] as String);
    default:
      throw AppFailure(FailureKind.validation, 'unknown entity $entity');
  }
};

/// Drains [AppDb.syncQueue] oldest first. No connectivity package: a network
/// failure parks the queue and retries with backoff, on app resume and on the
/// next write.
class SyncService {
  SyncService(this._db, this._push, {this.maxAttempts = 5});

  final AppDb _db;
  final Push _push;

  /// Unexplained server errors are retried this many times, then failed.
  final int maxAttempts;

  Future<void>? _running;
  var _dirty = false;
  var _backoff = 0;
  Timer? _retry;
  AppLifecycleListener? _life;

  void start() {
    _life = AppLifecycleListener(onResume: kick);
    // Ops left `syncing` by a killed app go out again (upserts are idempotent).
    unawaited(_db.requeue(opSyncing).then((_) => drain()));
  }

  void dispose() {
    _retry?.cancel();
    _life?.dispose();
  }

  void kick() => unawaited(drain());

  /// Completes when the queue is empty or parked; never throws.
  Future<void> drain() {
    _dirty = true;
    return _running ??= _loop().whenComplete(() => _running = null);
  }

  Future<void> retryFailed() async {
    await _db.requeue(opFailed);
    await drain();
  }

  Future<void> _loop() async {
    while (_dirty) {
      _dirty = false;
      for (var op = await _db.nextPending(); op != null;) {
        if (!await _send(op)) return;
        op = await _db.nextPending();
      }
    }
  }

  /// False when the queue should wait (offline or a transient error).
  Future<bool> _send(SyncOp op) async {
    await _db.updateOp(op.id, status: opSyncing, lastError: op.lastError);
    try {
      await _push(op.entity, jsonDecode(op.payload) as Map<String, dynamic>);
      await _db.deleteOp(op.id);
      _backoff = 0;
      return true;
    } catch (e) {
      final kind = mapError(e).kind;
      final network = kind == FailureKind.network;
      final attempts = op.attempts + (network ? 0 : 1);
      // MONTH_CLOSED, RLS refusal, validation…: retrying cannot help.
      final failed =
          !network && (kind != FailureKind.unknown || attempts >= maxAttempts);
      await _db.updateOp(
        op.id,
        status: failed ? opFailed : opPending,
        attempts: attempts,
        lastError: kind.name,
      );
      if (failed) return true;
      _retry?.cancel();
      _retry = Timer(
        Duration(seconds: min(300, 2 << min(_backoff++, 8))),
        kick,
      );
      return false;
    }
  }
}

/// Pending with an error = parked until the network is back: "saved offline".
SyncState opState(SyncOp? op) => switch (op?.status) {
  null => SyncState.synced,
  opFailed => SyncState.failed,
  opPending when op!.lastError != null => SyncState.offline,
  _ => SyncState.syncing,
};

/// The worst state in the queue: failed, then offline, then syncing.
SyncState queueState(Iterable<SyncOp> ops) {
  final states = ops.map(opState).toSet();
  for (final s in [SyncState.failed, SyncState.offline, SyncState.syncing]) {
    if (states.contains(s)) return s;
  }
  return SyncState.synced;
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final s = SyncService(
    ref.watch(appDbProvider),
    supabasePush(ref.watch(supabaseClientProvider)),
  )..start();
  ref.onDispose(s.dispose);
  return s;
});

final syncQueueProvider = StreamProvider<List<SyncOp>>(
  (ref) => ref.watch(appDbProvider).watchQueue(),
);
