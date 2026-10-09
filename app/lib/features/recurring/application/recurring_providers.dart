import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/supabase.dart';
import '../../money/application/money_providers.dart';
import '../../month/application/month_providers.dart';
import '../data/recurring_repository.dart';
import '../domain/recurring.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(ref.watch(supabaseClientProvider)),
);

final recurringBillsProvider =
    FutureProvider.family<List<RecurringExpense>, String>(
      (ref, messId) => ref.watch(recurringRepositoryProvider).bills(messId),
    );

/// Active bills not yet posted in the current period.
final pendingRecurringProvider = FutureProvider.family<int, String>(
  (ref, messId) =>
      ref.watch(recurringRepositoryProvider).pendingCount(messId, today()),
);

final mealDefaultsProvider =
    FutureProvider.family<Map<MealDefaultKey, double>, String>(
      (ref, messId) =>
          ref.watch(recurringRepositoryProvider).mealDefaults(messId),
    );

/// Mutations. Each throws `AppFailure` and refreshes what it changed.
final recurringControllerProvider = Provider<RecurringController>(
  RecurringController.new,
);

class RecurringController {
  RecurringController(this._ref);

  final Ref _ref;

  RecurringRepository get _repo => _ref.read(recurringRepositoryProvider);

  Future<void> saveBill(RecurringExpense b) async {
    try {
      await _repo.saveBill(b);
    } finally {
      _ref.invalidate(recurringBillsProvider(b.messId));
      _ref.invalidate(pendingRecurringProvider(b.messId));
      _ref.invalidate(attentionProvider(b.messId));
    }
  }

  /// Posts the current period's bills as expenses; returns how many.
  Future<int> apply(String messId) async {
    final n = await _repo.apply(messId, today());
    _ref.invalidate(pendingRecurringProvider(messId));
    _ref.invalidate(attentionProvider(messId));
    if (n > 0) {
      _ref.invalidate(expensesProvider(messId));
      _ref.invalidate(periodTotalsProvider);
      monthProviders(messId).forEach(_ref.invalidate);
    }
    return n;
  }

  Future<void> setMealDefault(
    String messId,
    MealDefaultKey key,
    double count,
  ) async {
    try {
      await _repo.setMealDefault(messId, key, count);
    } finally {
      _ref.invalidate(mealDefaultsProvider(messId));
    }
  }
}
