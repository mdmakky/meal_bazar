import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase.dart';
import '../../month/application/month_providers.dart';
import '../data/meal_repository.dart';
import '../domain/meal.dart';

final mealRepositoryProvider = Provider<MealRepository>(
  (ref) => MealRepository(ref.watch(supabaseClientProvider)),
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

  Future<int> fillDay(String messId, DateTime day) async {
    final n = await _repo.fillDay(messId, day);
    _refresh(messId, day);
    return n;
  }

  void _refresh(String messId, DateTime day) {
    _ref.invalidate(dayEntriesProvider((messId: messId, day: day)));
    _ref.invalidate(monthTotalsProvider(messId));
    _ref.invalidate(memberBalancesProvider(messId));
  }
}
