import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shopping_repository.dart';
import '../domain/shopping.dart';

/// Open and waiting lists of a mess that I may see (RLS: a manager sees all,
/// everyone else the lists they made or were given).
final shoppingListsProvider = FutureProvider.autoDispose
    .family<List<ShoppingList>, String>(
      (ref, messId) => ref.watch(shoppingRepositoryProvider).lists(messId),
    );

final shoppingControllerProvider = Provider<ShoppingController>(
  ShoppingController.new,
);

class ShoppingController {
  ShoppingController(this._ref);

  final Ref _ref;

  ShoppingRepository get _repo => _ref.read(shoppingRepositoryProvider);

  Future<void> saveList({
    required String id,
    required String messId,
    required DateTime date,
    String? title,
    String? note,
    String? assigneeId,
  }) async {
    await _repo.saveList(
      id: id,
      messId: messId,
      date: date,
      title: title,
      note: note,
      assigneeId: assigneeId,
    );
    _ref.invalidate(shoppingListsProvider(messId));
  }

  /// Items are saved on the phone one by one as they change (and sent when
  /// there is a network); the list view keeps its own copy, so nothing
  /// reloads under the shopper's thumb.
  Future<void> upsertItem(String messId, ShoppingItem i) =>
      _repo.upsertItem(messId, i);

  Future<void> deleteItem(String messId, String id) =>
      _repo.deleteItem(messId, id);

  Future<void> remember(ShoppingList l) => _repo.remember(l);

  Future<void> submit(ShoppingList l, {required bool ownPocket}) async {
    await _repo.submit(l, ownPocket: ownPocket);
    _ref.invalidate(shoppingListsProvider(l.messId));
  }

  Future<void> cancel(ShoppingList l) async {
    await _repo.cancel(l.id);
    _ref.invalidate(shoppingListsProvider(l.messId));
  }
}
