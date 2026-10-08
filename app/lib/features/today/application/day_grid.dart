import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../meals/application/meal_providers.dart';
import '../../meals/domain/meal.dart';

String cellKey(String memberId, String mealTypeId) => '$memberId|$mealTypeId';

/// One day's entries keyed by [cellKey], with optimistic writes on top.
final dayGridProvider =
    AsyncNotifierProvider.family<DayGrid, Map<String, MealEntry>, MessDay>(
      DayGrid.new,
    );

class DayGrid extends AsyncNotifier<Map<String, MealEntry>> {
  DayGrid(this.day);

  final MessDay day;

  /// Writes still in flight; they win over a refetch that raced them.
  final _pending = <String, MealEntry>{};

  @override
  Future<Map<String, MealEntry>> build() async {
    final list = await ref.watch(dayEntriesProvider(day).future);
    return {
      for (final e in list) cellKey(e.memberId, e.mealTypeId): e,
      ..._pending,
    };
  }

  /// Shows [e] at once, saves it, and reverts (then rethrows) on failure.
  Future<void> put(MealEntry e) async {
    final k = cellKey(e.memberId, e.mealTypeId);
    final before = state.value?[k];
    _pending[k] = e;
    _set(k, e);
    try {
      await ref.read(mealControllerProvider).save(day.messId, e);
    } catch (_) {
      if (ref.mounted && identical(_pending[k], e)) _set(k, before);
      rethrow;
    } finally {
      if (identical(_pending[k], e)) _pending.remove(k);
    }
  }

  void _set(String k, MealEntry? e) {
    final next = {...?state.value};
    e == null ? next.remove(k) : next[k] = e;
    state = AsyncData(next);
  }
}
