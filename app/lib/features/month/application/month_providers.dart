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

/// This period's spending by category, bazar included.
final spendingByCategoryProvider =
    FutureProvider.family<List<CategoryTotal>, String>((ref, messId) async {
      final period = await ref.watch(currentPeriodProvider(messId).future);
      return ref.watch(monthRepositoryProvider).byCategory(messId, period);
    });

/// The last 6 periods, oldest first (Home shows those with data).
final monthHistoryProvider = FutureProvider.family<List<MonthPoint>, String>(
  (ref, messId) => ref.watch(monthRepositoryProvider).history(messId),
);

/// Manager Home: what needs doing today (counts from SQL).
final attentionProvider = FutureProvider.family<Attention?, String>(
  (ref, messId) =>
      ref.watch(monthRepositoryProvider).attention(messId, today()),
);

/// This period's mess fund: verified deposits − fund-paid bazar/expenses.
final messCashProvider = FutureProvider.family<MessCash?, String>((
  ref,
  messId,
) async {
  final period = await ref.watch(currentPeriodProvider(messId).future);
  return ref.watch(monthRepositoryProvider).cash(messId, period);
});

/// Every member's deposits, own-pocket payments and balance this period.
final transparencyProvider =
    FutureProvider.family<List<MemberTransparency>, String>((
      ref,
      messId,
    ) async {
      final period = await ref.watch(currentPeriodProvider(messId).future);
      return ref.watch(monthRepositoryProvider).transparency(messId, period);
    });

/// Totals and per-member balances of the period that starts on `start`
/// (any month, not just the current one). Key by the period start so
/// flipping days inside one month reuses the result.
final periodSummaryProvider =
    FutureProvider.family<
      (MonthPeriod, MonthTotals, List<MemberBalance>),
      ({String messId, DateTime start})
    >((ref, k) async {
      final repo = ref.watch(monthRepositoryProvider);
      final p = await repo.period(k.messId, k.start);
      final (t, b) = await (
        repo.totals(k.messId, p),
        repo.balances(k.messId, p),
      ).wait;
      return (p, t, b);
    });

/// The caller's previous period, for the Home "last month" card.
final lastMonthProvider = FutureProvider.family<LastMonth?, String>(
  (ref, messId) => ref.watch(monthRepositoryProvider).lastMonth(messId),
);

/// What blocks closing `[from, to)`: pending deposits and bazar requests.
final pendingItemsProvider =
    FutureProvider.family<
      PendingItems,
      ({String messId, DateTime from, DateTime to})
    >(
      (ref, k) => ref
          .watch(monthRepositoryProvider)
          .pendingItems(k.messId, k.from, k.to),
    );

/// The start of the mess month containing [day], for [periodSummaryProvider]
/// keys only; SQL `month_period` still decides the real range.
DateTime periodStartFor(DateTime day, int monthStartDay) =>
    day.day >= monthStartDay
    ? DateTime(day.year, day.month, monthStartDay)
    : DateTime(day.year, day.month - 1, monthStartDay);

/// Everything that shows the month's SQL figures; invalidate all on a change.
List<ProviderOrFamily> monthProviders(String messId) => [
  monthTotalsProvider(messId),
  memberBalancesProvider(messId),
  spendingByCategoryProvider(messId),
  monthHistoryProvider(messId),
  attentionProvider(messId),
  messCashProvider(messId),
  transparencyProvider(messId),
  periodSummaryProvider,
  lastMonthProvider(messId),
  pendingItemsProvider,
];
