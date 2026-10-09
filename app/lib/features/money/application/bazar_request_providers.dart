import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase.dart';
import '../../month/application/month_providers.dart';
import '../data/bazar_request_repository.dart';
import '../domain/bazar_request.dart';
import 'money_providers.dart';

final bazarRequestRepositoryProvider = Provider<BazarRequestRepository>(
  (ref) => BazarRequestRepository(ref.watch(supabaseClientProvider)),
);

/// My own requests (messId, my member id), newest first.
final myBazarRequestsProvider =
    FutureProvider.family<List<BazarRequest>, (String, String)>(
      (ref, k) => ref.watch(bazarRequestRepositoryProvider).mine(k.$1, k.$2),
    );

/// The mess's pending requests, for managers.
final pendingBazarRequestsProvider =
    FutureProvider.family<List<BazarRequest>, String>(
      (ref, messId) =>
          ref.watch(bazarRequestRepositoryProvider).pending(messId),
    );

/// Mutations. Each throws `AppFailure` and refreshes what it changed.
final bazarRequestControllerProvider = Provider<BazarRequestController>(
  BazarRequestController.new,
);

class BazarRequestController {
  BazarRequestController(this._ref);

  final Ref _ref;

  BazarRequestRepository get _repo => _ref.read(bazarRequestRepositoryProvider);

  Future<void> submit(BazarRequest r) async {
    await _repo.submit(r);
    _lists(r.messId);
  }

  Future<void> cancel(BazarRequest r) async {
    await _repo.cancel(r.id);
    _lists(r.messId);
  }

  /// An approval is a new bazar: the list and every month figure refresh.
  Future<void> review(
    BazarRequest r, {
    required bool approve,
    String? reason,
  }) async {
    await _repo.review(r.id, approve: approve, reason: reason);
    _lists(r.messId);
    if (approve) {
      _ref.invalidate(bazarsProvider(r.messId));
      _ref.invalidate(frequentItemsProvider(r.messId));
      monthProviders(r.messId).forEach(_ref.invalidate);
      _ref.invalidate(periodTotalsProvider);
    }
  }

  void _lists(String messId) {
    _ref.invalidate(myBazarRequestsProvider);
    _ref.invalidate(pendingBazarRequestsProvider(messId));
    _ref.invalidate(attentionProvider(messId));
  }
}
