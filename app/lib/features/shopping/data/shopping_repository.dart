import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dates.dart';
import '../../../core/db/db.dart';
import '../../../core/db/sync.dart';
import '../../../core/errors.dart';
import '../../../core/ids.dart';
import '../../../core/supabase.dart';
import '../domain/shopping.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDbProvider),
    ref.watch(syncServiceProvider),
  ),
);

/// Lists are read online and remembered on the phone, so the market (weak
/// signal) still shows them. Ticks, prices and items are queued like meals
/// and bazars: saved here at once, sent when the network is back. Creating a
/// list, assigning it and sending it in as a bazar need the network.
/// The money is made by `submit_shopping_list` → the bazar request flow (0026).
class ShoppingRepository {
  ShoppingRepository(this._client, this._db, this._sync);

  final SupabaseClient _client;
  final AppDb _db;
  final SyncService _sync;

  static const _upsert = 'shopping_items';
  static const _delete = 'shopping_item_delete';

  /// The network, else what the phone remembers.
  Future<T> _orCached<T>(
    Future<T> Function() net,
    Future<T> Function() cache,
  ) async {
    try {
      return await net();
    } catch (e) {
      if (mapError(e).kind == FailureKind.network) return cache();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _cache(String messId) async {
    final raw = (await SharedPreferences.getInstance()).getString(
      'shopping_cache_$messId',
    );
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _store(String messId, Map<String, dynamic> m) async =>
      (await SharedPreferences.getInstance()).setString(
        'shopping_cache_$messId',
        jsonEncode(m),
      );

  /// Local edits not yet sent win over the server's copy (and the cache).
  Future<List<ShoppingList>> _overlay(List<ShoppingList> lists) async {
    final ups = await _db.opsFor(_upsert);
    final dels = await _db.opsFor(_delete);
    if (ups.isEmpty && dels.isEmpty) return lists;
    final pending = [
      for (final o in ups.values)
        ShoppingItem.fromJson(jsonDecode(o.payload) as Map<String, dynamic>),
    ];
    return [
      for (final l in lists)
        l.copyWith(
          items: [
            for (final i in l.items)
              if (!dels.containsKey(i.id) && !ups.containsKey(i.id)) i,
            for (final i in pending)
              if (i.listId == l.id && !dels.containsKey(i.id)) i,
          ]..sort((a, b) => a.sort.compareTo(b.sort)),
        ),
    ];
  }

  /// Lists I can see that are still going on, newest day first.
  Future<List<ShoppingList>> lists(String messId) => guard(
    () => _orCached(
      () async {
        final rows = await _client
            .from('shopping_lists')
            .select('*, shopping_items(*)')
            .eq('mess_id', messId)
            .inFilter('status', ['open', 'submitted'])
            .order('date', ascending: false)
            .order('created_at', ascending: false);
        final lists = rows.map(ShoppingList.fromJson).toList();
        await _store(messId, {for (final l in lists) l.id: l.toJson()});
        return _overlay(lists);
      },
      () async {
        final lists = [
          for (final j in (await _cache(messId)).values)
            ShoppingList.fromJson(j as Map<String, dynamic>),
        ]..sort((a, b) => b.date.compareTo(a.date));
        return _overlay(lists);
      },
    ),
  );

  Future<ShoppingList?> list(String messId, String id) => guard(
    () => _orCached(
      () async {
        final rows = await _client
            .from('shopping_lists')
            .select('*, shopping_items(*)')
            .eq('id', id);
        if (rows.isEmpty) return null;
        final l = ShoppingList.fromJson(rows.first);
        await remember(l);
        return (await _overlay([l])).first;
      },
      () async {
        final j = (await _cache(messId))[id];
        if (j == null) return null;
        return (await _overlay([
          ShoppingList.fromJson(j as Map<String, dynamic>),
        ])).first;
      },
    ),
  );

  /// Keeps the phone's copy of a list in step with what the screen shows.
  Future<void> remember(ShoppingList l) async {
    final m = await _cache(l.messId);
    if (l.isOpen || l.status == 'submitted') {
      m[l.id] = l.toJson();
    } else {
      m.remove(l.id);
    }
    await _store(l.messId, m);
  }

  Future<void> saveList({
    required String id,
    required String messId,
    required DateTime date,
    String? title,
    String? note,
    String? assigneeId,
  }) => guard(
    () => _client.rpc(
      'save_shopping_list',
      params: {
        'p_id': id,
        'p_mess': messId,
        'p_date': isoDate(date),
        'p_title': title,
        'p_note': note,
        'p_assignee': assigneeId,
      },
    ),
  );

  /// Saved on the phone and queued; waits for one sync attempt.
  Future<void> upsertItem(String messId, ShoppingItem i) => guard(() async {
    await _db.enqueue(_upsert, i.id, uuidV4(), {
      ...i.toJson(),
      'mess_id': messId,
    });
    await _sync.drain();
  });

  Future<void> deleteItem(String messId, String id) => guard(() async {
    // An edit still waiting for this item no longer matters.
    final waiting = (await _db.opsFor(_upsert))[id];
    if (waiting != null) await _db.deleteOp(waiting.id);
    await _db.enqueue(_delete, id, uuidV4(), {'id': id, 'mess_id': messId});
    await _sync.drain();
  });

  /// Needs the network, and every tick and price of this list already sent.
  Future<void> submit(ShoppingList l, {required bool ownPocket}) =>
      guard(() async {
        await _sync.drain();
        final waiting = [
          for (final o in (await _db.opsFor(_upsert)).values)
            if ((jsonDecode(o.payload) as Map)['list_id'] == l.id) o,
          ...(await _db.opsFor(
            _delete,
          )).values.where((o) => o.messId == l.messId),
        ];
        if (waiting.isNotEmpty) throw const AppFailure(FailureKind.network);
        await _client.rpc(
          'submit_shopping_list',
          params: {'p_list': l.id, 'p_own_pocket': ownPocket},
        );
      });

  Future<void> cancel(String listId) => guard(
    () => _client.rpc('cancel_shopping_list', params: {'p_list': listId}),
  );
}
