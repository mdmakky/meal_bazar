import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/db.dart';
import '../../../core/supabase.dart';
import '../../auth/application/auth_providers.dart';
import '../../month/application/month_providers.dart';
import '../data/mess_repository.dart';
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
  return ref.watch(messRepositoryProvider).myMemberships();
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
    return id;
  }

  Future<String> createInvite(String messId) => _repo.createInvite(messId);

  Future<String> joinMess({
    required String code,
    required String displayName,
  }) async {
    final id = await _repo.joinMess(code: code, displayName: displayName);
    _ref.invalidate(myMembershipsProvider);
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

  Future<void> setStatus(Member m, MemberStatus status) =>
      _changed(m, () => _repo.setStatus(m.id, status));

  Future<Mess> updateMess(
    String messId, {
    String? name,
    String? address,
    int? monthStartDay,
    String? mealOffCutoff,
    bool? fixedRate,
    double? fixedMealRate,
  }) async {
    final mess = await _repo.updateMess(
      messId,
      name: name,
      address: address,
      monthStartDay: monthStartDay,
      mealOffCutoff: mealOffCutoff,
      fixedRate: fixedRate,
      fixedMealRate: fixedMealRate,
    );
    _ref.invalidate(myMembershipsProvider);
    // The rate mode changes every month figure.
    monthProviders(messId).forEach(_ref.invalidate);
    return mess;
  }

  /// The change may concern me (leaving, demoting myself), so refresh both.
  Future<void> _changed(Member m, Future<Object?> Function() change) async {
    await change();
    _ref.invalidate(membersProvider(m.messId));
    _ref.invalidate(myMembershipsProvider);
  }
}
