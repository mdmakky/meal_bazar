import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_config.dart';
import '../../mess/application/mess_providers.dart';
import '../../reminders/application/reminder_service.dart';
import '../data/duty_repository.dart';
import '../domain/duty.dart';

/// Duties for (messId, from, to), both days inclusive. Each load also
/// schedules a reminder for my own upcoming, not-done duties.
final dutiesProvider = FutureProvider.autoDispose
    .family<List<BazarDuty>, (String, DateTime, DateTime)>((ref, k) async {
      final list = await ref
          .watch(dutyRepositoryProvider)
          .duties(k.$1, k.$2, k.$3);
      final me = ref.read(currentMembershipProvider);
      if (me != null && ref.read(platformConfigProvider).feature('reminders')) {
        final reminders = ref.read(reminderServiceProvider);
        for (final d in list) {
          if (d.memberId != me.member.id || d.done) continue;
          // Best-effort: past dates and "duty off" are skipped by the service.
          reminders
              .scheduleDutyReminder(d.date, me.mess?.name ?? '')
              .catchError((Object e) => debugPrint('duty reminder: $e'));
        }
      }
      return list;
    });

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
