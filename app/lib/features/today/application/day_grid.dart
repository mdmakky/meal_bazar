import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../meals/application/meal_providers.dart';
import '../../meals/domain/meal.dart';

/// The clock, overridable in tests (meal-off cutoff).
final nowProvider = Provider<DateTime Function()>((_) => DateTime.now);

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
  /// [own]: a member switching their own meal off/on (`set_my_meal_off`).
  Future<void> put(MealEntry e, {bool own = false}) async {
    final k = cellKey(e.memberId, e.mealTypeId);
    final before = state.value?[k];
    _pending[k] = e;
    _set(k, e);
    try {
      final meals = ref.read(mealControllerProvider);
      await (own
          ? meals.setMyMealOff(day.messId, e)
          : meals.save(day.messId, e));
    } catch (_) {
      if (ref.mounted && identical(_pending[k], e)) _set(k, before);
      rethrow;
    } finally {
      if (identical(_pending[k], e)) _pending.remove(k);
    }
  }

  /// [put] for many cells at once (bulk actions); all revert on failure.
  Future<void> putAll(List<MealEntry> entries) async {
    if (entries.isEmpty) return;
    final before = {...?state.value};
    final next = {...before};
    for (final e in entries) {
      final k = cellKey(e.memberId, e.mealTypeId);
      _pending[k] = e;
      next[k] = e;
    }
    state = AsyncData(next);
    try {
      await ref.read(mealControllerProvider).saveAll(day.messId, entries);
    } catch (_) {
      if (ref.mounted) {
        final reverted = {...?state.value};
        for (final e in entries) {
          final k = cellKey(e.memberId, e.mealTypeId);
          if (!identical(_pending[k], e)) continue;
          final old = before[k];
          old == null ? reverted.remove(k) : reverted[k] = old;
        }
        state = AsyncData(reverted);
      }
      rethrow;
    } finally {
      for (final e in entries) {
        final k = cellKey(e.memberId, e.mealTypeId);
        if (identical(_pending[k], e)) _pending.remove(k);
      }
    }
  }

  void _set(String k, MealEntry? e) {
    final next = {...?state.value};
    e == null ? next.remove(k) : next[k] = e;
    state = AsyncData(next);
  }
}
