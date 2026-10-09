import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/db.dart';
import '../../../core/db/sync.dart';
import '../../../core/supabase.dart';
import '../../month/application/month_providers.dart';
import '../data/meal_repository.dart';
import '../domain/meal.dart';

final mealRepositoryProvider = Provider<MealRepository>(
  (ref) => MealRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDbProvider),
    ref.watch(syncServiceProvider),
  ),
);

/// All meal types (enabled and disabled), in display order.
final mealTypesProvider = FutureProvider.family<List<MealType>, String>(
  (ref, messId) => ref.watch(mealRepositoryProvider).mealTypes(messId),
);

typedef MessDay = ({String messId, DateTime day});

final dayEntriesProvider = FutureProvider.family<List<MealEntry>, MessDay>(
  (ref, key) =>
      ref.watch(mealRepositoryProvider).entriesForDay(key.messId, key.day),
);

/// Cells the midnight job filled on a day (`memberId|mealTypeId`); `putEntry`
/// invalidates it so an edited cell loses its marker.
final autoFilledProvider = FutureProvider.family<Set<String>, MessDay>((
  ref,
  key,
) async {
  try {
    return await ref
        .watch(mealRepositoryProvider)
        .autoFilledOnDay(key.messId, key.day);
  } catch (_) {
    return const {}; // a marker, not data: offline or an error shows none
  }
});

/// Meal-off deadlines on a day by meal type id (SQL `meal_off_deadlines`).
final mealOffDeadlinesProvider =
    FutureProvider.family<Map<String, DateTime>, MessDay>(
      (ref, key) => ref
          .watch(mealRepositoryProvider)
          .mealOffDeadlines(key.messId, key.day),
    );

typedef MealRange = ({
  String messId,
  DateTime from,
  DateTime to,
  String? memberId,
});

final rangeEntriesProvider = FutureProvider.family<List<MealEntry>, MealRange>(
  (ref, k) => ref
      .watch(mealRepositoryProvider)
      .entriesForRange(k.messId, k.from, k.to, memberId: k.memberId),
);

/// Guest meals per member for the current period (SQL `member_meal_totals`).
final guestMealsProvider = FutureProvider.family<Map<String, double>, String>((
  ref,
  messId,
) async {
  final p = await ref.watch(currentPeriodProvider(messId).future);
  return ref.watch(mealRepositoryProvider).guestMeals(messId, p.start, p.end);
});

final mealControllerProvider = Provider<MealController>(MealController.new);

class MealController {
  MealController(this._ref);

  final Ref _ref;

  MealRepository get _repo => _ref.read(mealRepositoryProvider);

  Future<void> save(
    String messId,
    MealEntry entry, {
    String source = 'app',
  }) async {
    await _repo.save(messId, entry, source: source);
    _refresh(messId, entry.date);
  }

  /// One day's bulk change ("সবাই ১", "গতকালের মতো") in one write.
  Future<void> saveAll(String messId, List<MealEntry> entries) async {
    if (entries.isEmpty) return;
    await _repo.saveAll(messId, entries);
    for (final d in {for (final e in entries) e.date}) {
      _refresh(messId, d);
    }
  }

  /// My own meal off/on via `set_my_meal_off` (members, before the cutoff).
  Future<void> setMyMealOff(String messId, MealEntry entry) async {
    await _repo.setMyMealOff(
      messId,
      entry.date,
      entry.mealTypeId,
      off: entry.isOff,
    );
    _refresh(messId, entry.date);
  }

  Future<int> fillDay(String messId, DateTime day) async {
    final n = await _repo.fillDay(messId, day);
    _refresh(messId, day);
    return n;
  }

  Future<void> createMealType(
    String messId, {
    required String name,
    required int sortOrder,
  }) async {
    await _repo.createMealType(messId, name: name, sortOrder: sortOrder);
    _ref.invalidate(mealTypesProvider(messId));
  }

  /// A weight change re-prices the month, so money figures refresh too.
  Future<void> updateMealType(
    MealType t, {
    String? name,
    double? weight,
    bool? enabled,
    String? serveTime,
  }) async {
    await _repo.updateMealType(
      t.id,
      name: name,
      weight: weight,
      enabled: enabled,
      serveTime: serveTime,
    );
    _ref.invalidate(mealTypesProvider(t.messId));
    if (serveTime != null) _ref.invalidate(mealOffDeadlinesProvider);
    if (weight != null) _refreshMonth(t.messId);
  }

  /// Writes `sort_order` = position for every type whose position changed.
  Future<void> reorderMealTypes(String messId, List<MealType> ordered) async {
    try {
      await Future.wait([
        for (final (i, t) in ordered.indexed)
          if (t.sortOrder != i) _repo.updateMealType(t.id, sortOrder: i),
      ]);
    } finally {
      _ref.invalidate(mealTypesProvider(messId));
    }
  }

  void _refresh(String messId, DateTime day) {
    _ref.invalidate(dayEntriesProvider((messId: messId, day: day)));
    _ref.invalidate(rangeEntriesProvider);
    _refreshMonth(messId);
  }

  void _refreshMonth(String messId) {
    monthProviders(messId).forEach(_ref.invalidate);
    _ref.invalidate(guestMealsProvider(messId));
  }
}
