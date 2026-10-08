import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/dates.dart';
import '../../../core/supabase.dart';
import '../data/month_repository.dart';
import '../domain/month.dart';

final monthRepositoryProvider = Provider<MonthRepository>(
  (ref) => MonthRepository(ref.watch(supabaseClientProvider)),
);

/// The billing period containing today.
final currentPeriodProvider = FutureProvider.family<MonthPeriod, String>(
  (ref, messId) => ref.watch(monthRepositoryProvider).period(messId, today()),
);

final monthTotalsProvider = FutureProvider.family<MonthTotals, String>((
  ref,
  messId,
) async {
  final period = await ref.watch(currentPeriodProvider(messId).future);
  return ref.watch(monthRepositoryProvider).totals(messId, period);
});

final memberBalancesProvider =
    FutureProvider.family<List<MemberBalance>, String>((ref, messId) async {
      final period = await ref.watch(currentPeriodProvider(messId).future);
      return ref.watch(monthRepositoryProvider).balances(messId, period);
    });

/// Billable meals per day of the current period (dashboard trend).
final dailyMealsProvider = FutureProvider.family<List<DayMeals>, String>((
  ref,
  messId,
) async {
  final period = await ref.watch(currentPeriodProvider(messId).future);
  return ref.watch(monthRepositoryProvider).dailyMeals(messId, period);
});

/// This period's spending by category, bazar included.
final spendingByCategoryProvider =
    FutureProvider.family<List<CategoryTotal>, String>((ref, messId) async {
      final period = await ref.watch(currentPeriodProvider(messId).future);
      return ref.watch(monthRepositoryProvider).byCategory(messId, period);
    });

/// The last 6 periods, oldest first.
final monthHistoryProvider = FutureProvider.family<List<MonthPoint>, String>(
  (ref, messId) => ref.watch(monthRepositoryProvider).history(messId),
);

/// Everything that shows the month's SQL figures; invalidate all on a change.
List<ProviderOrFamily> monthProviders(String messId) => [
  monthTotalsProvider(messId),
  memberBalancesProvider(messId),
  dailyMealsProvider(messId),
  spendingByCategoryProvider(messId),
  monthHistoryProvider(messId),
];
