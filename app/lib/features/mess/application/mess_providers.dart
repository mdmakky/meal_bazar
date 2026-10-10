import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/db.dart';
import '../../../core/supabase.dart';
import '../../auth/application/auth_providers.dart';
import '../../meals/application/meal_providers.dart';
import '../../month/application/month_providers.dart';
import '../../push/application/push_service.dart';
import '../data/mess_repository.dart';
import '../domain/invite_preview.dart';
import '../domain/member.dart';
import '../domain/mess.dart';

final messRepositoryProvider = Provider<MessRepository>(
  (ref) => MessRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDbProvider),
  ),
);

/// My memberships; empty when signed out.
final myMembershipsProvider = FutureProvider<List<Membership>>((ref) async {
  final uid = await ref.watch(authStateProvider.future);
  if (uid == null) return const [];
  // Cold start: from cache at once; refetch if the server differs.
  return ref
      .watch(messRepositoryProvider)
      .myMemberships(
        onStale: ref.isFirstBuild
            ? () {
                if (ref.mounted) ref.invalidateSelf();
              }
            : null,
      );
});

/// The mess the user is looking at. Defaults to the first active membership
/// and keeps the user's choice while it stays a usable membership.
final currentMessIdProvider = NotifierProvider<CurrentMessId, String?>(
  CurrentMessId.new,
);

class CurrentMessId extends Notifier<String?> {
  @override
  String? build() {
    final usable = (ref.watch(myMembershipsProvider).value ?? const [])
        .where((m) => m.mess != null)
        .toList();
    final previous = stateOrNull;
    if (usable.any((m) => m.messId == previous)) return previous;
    final active = usable.where((m) => m.member.status == MemberStatus.active);
    return (active.isNotEmpty ? active.first : usable.firstOrNull)?.messId;
  }

  void select(String messId) => state = messId;
}

/// My membership in the current mess.
final currentMembershipProvider = Provider<Membership?>((ref) {
  final id = ref.watch(currentMessIdProvider);
  final list = ref.watch(myMembershipsProvider).value ?? const [];
  return list.where((m) => m.messId == id).firstOrNull;
});

final currentMessProvider = Provider<Mess?>(
  (ref) => ref.watch(currentMembershipProvider)?.mess,
);

/// UX only — RLS is the real check.
final amIManagerProvider = Provider<bool>(
  (ref) =>
      ref.watch(currentMembershipProvider)?.member.isActiveManager ?? false,
);

final membersProvider = FutureProvider.family<List<Member>, String>(
  (ref, messId) => ref.watch(messRepositoryProvider).members(messId),
);

/// Ids of members who left the mess (empty while the members load).
final leftMemberIdsProvider = Provider.family<Set<String>, String>(
  (ref, messId) => {
    for (final m in ref.watch(membersProvider(messId)).value ?? const [])
      if (m.status == MemberStatus.left) m.id,
  },
);

/// Who invited me to which mess; keyed by the invite code.
final invitePreviewProvider = FutureProvider.family<InvitePreview, String>(
  (ref, code) => ref.watch(messRepositoryProvider).invitePreview(code),
);

/// The manager's due-reminder texts (supabase 0030).
final dueReminderTextsProvider =
    FutureProvider.family<List<DueReminderText>, String>(
      (ref, messId) =>
          ref.watch(messRepositoryProvider).dueReminderTexts(messId),
    );

/// Mutations. Each throws `AppFailure` and refreshes what it changed.
final messControllerProvider = Provider<MessController>(MessController.new);

class MessController {
  MessController(this._ref);

  final Ref _ref;

  MessRepository get _repo => _ref.read(messRepositoryProvider);

  Future<String> createMess({
    required String name,
    required String displayName,
    int monthStartDay = 1,
  }) async {
    final id = await _repo.createMess(
      name: name,
      displayName: displayName,
      monthStartDay: monthStartDay,
    );
    _ref.invalidate(myMembershipsProvider);
    _ref.read(currentMessIdProvider.notifier).select(id);
    unawaited(askNotificationPermission(_ref));
    return id;
  }

  Future<({double balance, bool onlyManager})?> leavePreview(String messId) =>
      _repo.leavePreview(messId);

  Future<void> leaveMess(String messId) async {
    await _repo.leaveMess(messId);
    _ref.invalidate(myMembershipsProvider);
  }

  Future<void> requestLeave(String messId) => _repo.requestLeave(messId);

  Future<void> requestDeletion(String messId, String name) async {
    await _repo.requestDeletion(messId, name);
    _ref.invalidate(myMembershipsProvider);
  }

  Future<void> cancelDeletion(String messId) async {
    await _repo.cancelDeletion(messId);
    _ref.invalidate(myMembershipsProvider);
  }

  Future<String> createInvite(String messId) => _repo.createInvite(messId);

  Future<String> createInviteLink(String messId, {String? inviteeName}) =>
      _repo.createInviteLink(messId, inviteeName: inviteeName);

  Future<String> joinMess({
    required String code,
    required String displayName,
  }) async {
    final id = await _repo.joinMess(code: code, displayName: displayName);
    _ref.invalidate(myMembershipsProvider);
    unawaited(askNotificationPermission(_ref));
    return id;
  }

  Future<Member> addOfflineMember({
    required String messId,
    required String displayName,
    String? room,
  }) async {
    final m = await _repo.addOfflineMember(
      messId: messId,
      displayName: displayName,
      room: room,
    );
    _ref.invalidate(membersProvider(messId));
    return m;
  }

  Future<void> approveMember(Member m) =>
      _changed(m, () => _repo.approveMember(m.id));

  Future<void> rejectMember(Member m) =>
      _changed(m, () => _repo.rejectMember(m.id));

  Future<void> setRole(Member m, MemberRole role) =>
      _changed(m, () => _repo.setRole(m.id, role));

  Future<void> setMealOnly(Member m, bool v) async {
    await _changed(m, () => _repo.setMealOnly(m.id, v));
    monthProviders(m.messId).forEach(_ref.invalidate); // shares change balances
  }

  Future<void> setStatus(Member m, MemberStatus status) =>
      _changed(m, () => _repo.setStatus(m.id, status));

  Future<Mess> updateMess(
    String messId, {
    String? name,
    String? address,
    int? monthStartDay,
    String? mealOffCutoff,
    MealOffLead? mealOffLead,
    bool? fixedRate,
    double? fixedMealRate,
  }) async {
    final mess = await _repo.updateMess(
      messId,
      name: name,
      address: address,
      monthStartDay: monthStartDay,
      mealOffCutoff: mealOffCutoff,
      mealOffLead: mealOffLead,
      fixedRate: fixedRate,
      fixedMealRate: fixedMealRate,
    );
    _ref.invalidate(myMembershipsProvider);
    // The rate mode changes every month figure.
    monthProviders(messId).forEach(_ref.invalidate);
    _ref.invalidate(mealOffDeadlinesProvider);
    return mess;
  }

  Future<void> setDueReminders(
    String messId, {
    required int? every,
    required double min,
  }) async {
    await _repo.setDueReminders(messId, every: every, min: min);
    _ref.invalidate(myMembershipsProvider);
  }

  Future<void> setFundMode(String messId, bool on) async {
    await _repo.setFundMode(messId, on);
    _ref.invalidate(myMembershipsProvider);
  }

  Future<void> setAutoMeals(String messId, bool on) async {
    await _repo.setAutoMeals(messId, on);
    _ref.invalidate(myMembershipsProvider);
  }

  Future<void> saveDueReminderText(String messId, DueReminderText t) async {
    try {
      await _repo.saveDueReminderText(messId, t);
    } finally {
      _ref.invalidate(dueReminderTextsProvider(messId));
    }
  }

  Future<void> deleteDueReminderText(String messId, String id) async {
    try {
      await _repo.deleteDueReminderText(id);
    } finally {
      _ref.invalidate(dueReminderTextsProvider(messId));
    }
  }

  /// The change may concern me (leaving, demoting myself), so refresh both.
  Future<void> _changed(Member m, Future<Object?> Function() change) async {
    await change();
    _ref.invalidate(membersProvider(m.messId));
    _ref.invalidate(myMembershipsProvider);
    _ref.invalidate(attentionProvider(m.messId));
  }
}
