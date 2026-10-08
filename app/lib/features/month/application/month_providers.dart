import 'package:flutter_riverpod/flutter_riverpod.dart';

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
