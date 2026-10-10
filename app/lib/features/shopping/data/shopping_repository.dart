import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dates.dart';
import '../../../core/errors.dart';
import '../../../core/supabase.dart';
import '../domain/shopping.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(ref.watch(supabaseClientProvider)),
);

/// Online only, like the duty roster: a list is a plan, not money. The
/// money is made by `submit_shopping_list` → the bazar request flow (0026).
class ShoppingRepository {
  ShoppingRepository(this._client);

  final SupabaseClient _client;

  /// Lists I can see that are still going on, newest day first.
  Future<List<ShoppingList>> lists(String messId) => guard(() async {
    final rows = await _client
        .from('shopping_lists')
        .select('*, shopping_items(*)')
        .eq('mess_id', messId)
        .inFilter('status', ['open', 'submitted'])
        .order('date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(ShoppingList.fromJson).toList();
  });

  Future<ShoppingList?> list(String id) => guard(() async {
    final rows = await _client
        .from('shopping_lists')
        .select('*, shopping_items(*)')
        .eq('id', id);
    return rows.isEmpty ? null : ShoppingList.fromJson(rows.first);
  });

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

  Future<void> upsertItem(ShoppingItem i) => guard(() async {
    requireRows(
      await _client.from('shopping_items').upsert(i.toJson()).select(),
    );
  });

  Future<void> deleteItem(String id) =>
      guard(() => _client.from('shopping_items').delete().eq('id', id));

  Future<void> submit(String listId, {required bool ownPocket}) => guard(
    () => _client.rpc(
      'submit_shopping_list',
      params: {'p_list': listId, 'p_own_pocket': ownPocket},
    ),
  );

  Future<void> cancel(String listId) => guard(
    () => _client.rpc('cancel_shopping_list', params: {'p_list': listId}),
  );
}
