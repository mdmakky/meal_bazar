import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mess/application/mess_providers.dart';
import '../data/duty_repository.dart';
import '../domain/duty.dart';

/// Duties for (messId, from, to), both days inclusive.
final dutiesProvider = FutureProvider.autoDispose
    .family<List<BazarDuty>, (String, DateTime, DateTime)>(
      (ref, k) => ref.watch(dutyRepositoryProvider).duties(k.$1, k.$2, k.$3),
    );

/// Mutations. Each throws `AppFailure` and refreshes every duty list.
final dutyControllerProvider = Provider<DutyController>(DutyController.new);

class DutyController {
  DutyController(this._ref);

  final Ref _ref;

  DutyRepository get _repo => _ref.read(dutyRepositoryProvider);

  Future<int> generate(String messId, DutyRotation r) =>
      _changed(() => _repo.generate(messId, r));

  Future<void> save(BazarDuty d) => _changed(() => _repo.save(d));

  Future<void> delete(BazarDuty d) => _changed(() => _repo.delete(d.id));

  /// My own duty goes through the RPC; a manager edits anyone's row.
  Future<void> setDone(BazarDuty d, bool done) {
    final mine = _ref.read(currentMembershipProvider)?.member.id == d.memberId;
    return _changed(
      () => mine
          ? _repo.markMine(d.id, done)
          : _repo.save(d.copyWith(done: done)),
    );
  }

  Future<T> _changed<T>(Future<T> Function() change) async {
    final r = await change();
    _ref.invalidate(dutiesProvider);
    return r;
  }
}
