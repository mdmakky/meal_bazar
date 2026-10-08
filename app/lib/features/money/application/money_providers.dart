import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/db/db.dart';
import '../../../core/db/sync.dart';
import '../../../core/supabase.dart';
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';
import '../data/money_repository.dart';
import '../domain/bazar_catalogue.dart';
import '../domain/money.dart';

final moneyRepositoryProvider = Provider<MoneyRepository>(
  (ref) => MoneyRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDbProvider),
    ref.watch(syncServiceProvider),
  ),
);

typedef Paged<T> = ({List<T> items, bool hasMore});

typedef _Fetch<T> =
    Future<List<T>> Function(
      MoneyRepository repo,
      String messId,
      MonthPeriod period,
      int from,
    );

/// A current-month list loaded [moneyPageSize] rows at a time.
class PagedList<T> extends AsyncNotifier<Paged<T>> {
  PagedList(this.messId, this._fetch);

  final String messId;
  final _Fetch<T> _fetch;

  @override
  Future<Paged<T>> build() async {
    final period = await ref.watch(currentPeriodProvider(messId).future);
    final rows = await _fetch(
      ref.watch(moneyRepositoryProvider),
      messId,
      period,
      0,
    );
    return (items: rows, hasMore: rows.length == moneyPageSize);
  }

  /// Throws `AppFailure`; the loaded rows stay.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final period = await ref.read(currentPeriodProvider(messId).future);
    final rows = await _fetch(
      ref.read(moneyRepositoryProvider),
      messId,
      period,
      current.items.length,
    );
    if (!ref.mounted) return;
    state = AsyncData((
      items: [...current.items, ...rows],
      hasMore: rows.length == moneyPageSize,
    ));
  }
}

final bazarsProvider =
    AsyncNotifierProvider.family<PagedList<Bazar>, Paged<Bazar>, String>(
      (messId) =>
          PagedList(messId, (r, m, p, from) => r.bazars(m, p, from: from)),
    );

final expensesProvider =
    AsyncNotifierProvider.family<PagedList<Expense>, Paged<Expense>, String>(
      (messId) =>
          PagedList(messId, (r, m, p, from) => r.expenses(m, p, from: from)),
    );

final depositsProvider =
    AsyncNotifierProvider.family<PagedList<Deposit>, Paged<Deposit>, String>(
      (messId) =>
          PagedList(messId, (r, m, p, from) => r.deposits(m, p, from: from)),
    );

/// The bazar picker's "বেশি কেনা হয়": top 6 item names by frequency.
final frequentItemsProvider = FutureProvider.family<List<String>, String>(
  (ref, messId) async =>
      frequentItems(await ref.watch(moneyRepositoryProvider).itemNames(messId)),
);

final expenseCategoriesProvider =
    FutureProvider.family<List<ExpenseCategory>, String>(
      (ref, messId) => ref.watch(moneyRepositoryProvider).categories(messId),
    );

final monthsProvider = FutureProvider.family<List<MessMonth>, String>(
  (ref, messId) => ref.watch(moneyRepositoryProvider).months(messId),
);

typedef MessDate = ({String messId, DateTime day});

/// The billing period containing a given day, with its SQL totals.
final periodTotalsProvider =
    FutureProvider.family<(MonthPeriod, MonthTotals), MessDate>((
      ref,
      key,
    ) async {
      final months = ref.watch(monthRepositoryProvider);
      final period = await months.period(key.messId, key.day);
      return (period, await months.totals(key.messId, period));
    });

/// Mutations. Each throws `AppFailure` and refreshes what it changed.
final moneyControllerProvider = Provider<MoneyController>(MoneyController.new);

class MoneyController {
  MoneyController(this._ref);

  final Ref _ref;

  MoneyRepository get _repo => _ref.read(moneyRepositoryProvider);

  Future<void> saveBazar(Bazar b) async {
    await _repo.saveBazar(b);
    _ref.invalidate(frequentItemsProvider(b.messId));
    _changed(b.messId, bazarsProvider(b.messId));
  }

  Future<void> deleteBazar(Bazar b) async {
    await _repo.deleteBazar(b.id);
    _changed(b.messId, bazarsProvider(b.messId));
  }

  Future<void> saveExpense(Expense e) async {
    await _repo.saveExpense(e);
    _changed(e.messId, expensesProvider(e.messId));
  }

  Future<void> deleteExpense(Expense e) async {
    await _repo.deleteExpense(e.id);
    _changed(e.messId, expensesProvider(e.messId));
  }

  Future<void> saveDeposit(Deposit d) async {
    await _repo.saveDeposit(d);
    _changed(d.messId, depositsProvider(d.messId));
  }

  Future<void> recordMyDeposit(Deposit d) async {
    await _repo.recordMyDeposit(d);
    _changed(d.messId, depositsProvider(d.messId));
  }

  Future<void> verifyDeposit(Deposit d, {required bool approve}) async {
    await _repo.verifyDeposit(d.id, approve: approve);
    _changed(d.messId, depositsProvider(d.messId));
  }

  Future<void> deleteDeposit(Deposit d) async {
    await _repo.deleteDeposit(d.id);
    _changed(d.messId, depositsProvider(d.messId));
  }

  Future<void> closeMonth(String messId, DateTime day) async {
    await _repo.closeMonth(messId, day);
    _changed(messId, monthsProvider(messId));
  }

  Future<void> reopenMonth(String messId, String monthId, String reason) async {
    await _repo.reopenMonth(monthId, reason);
    _changed(messId, monthsProvider(messId));
  }

  void _changed(String messId, ProviderOrFamily list) {
    _ref.invalidate(list);
    monthProviders(messId).forEach(_ref.invalidate);
    _ref.invalidate(periodTotalsProvider);
  }
}
