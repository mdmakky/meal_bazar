import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/data/mess_repository.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:mocktail/mocktail.dart';

class MockMessRepository extends Mock implements MessRepository {}

Map<String, dynamic> memberRow(
  String messId, {
  String role = 'member',
  String status = 'active',
  bool withMess = true,
}) => {
  'id': 'm-$messId',
  'mess_id': messId,
  'user_id': 'u1',
  'display_name': 'Rahim',
  'role': role,
  'status': status,
  'joined_on': '2026-10-01',
  'left_on': null,
  'room': '3B',
  'notes': null,
  'messes': withMess
      ? {
          'id': messId,
          'name': 'Mess $messId',
          'month_start_day': 1,
          'currency': '৳',
          'meal_off_cutoff': '22:00:00',
          'address': null,
          'created_by': 'u1',
        }
      : null,
};

void main() {
  test('Membership.fromJson parses member and joined mess', () {
    final m = Membership.fromJson(memberRow('a', role: 'manager'));
    expect(m.member.role, MemberRole.manager);
    expect(m.member.status, MemberStatus.active);
    expect(m.member.joinedOn, DateTime(2026, 10, 1));
    expect(m.member.isActiveManager, isTrue);
    expect(m.mess?.name, 'Mess a');
    expect(m.mess?.monthStartDay, 1);
  });

  test('pending membership has no mess (hidden by RLS)', () {
    final m = Membership.fromJson(
      memberRow('a', status: 'pending', withMess: false),
    );
    expect(m.member.status, MemberStatus.pending);
    expect(m.mess, isNull);
  });

  group('current mess', () {
    ProviderContainer containerWith(List<Map<String, dynamic>> rows) {
      final c = ProviderContainer(
        overrides: [
          myMembershipsProvider.overrideWith(
            (ref) async => rows.map(Membership.fromJson).toList(),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(currentMessIdProvider, (_, _) {});
      return c;
    }

    test('defaults to the first active membership', () async {
      final c = containerWith([
        memberRow('p', status: 'pending', withMess: false),
        memberRow('i', status: 'inactive'),
        memberRow('a', role: 'manager'),
      ]);
      await c.read(myMembershipsProvider.future);
      expect(c.read(currentMessIdProvider), 'a');
      expect(c.read(currentMessProvider)?.name, 'Mess a');
      expect(c.read(amIManagerProvider), isTrue);
    });

    test('keeps a valid selection', () async {
      final c = containerWith([memberRow('a'), memberRow('b')]);
      await c.read(myMembershipsProvider.future);
      c.read(currentMessIdProvider.notifier).select('b');
      expect(c.read(currentMessIdProvider), 'b');
      expect(c.read(amIManagerProvider), isFalse);
    });

    test('null when there are no memberships', () async {
      final c = containerWith([]);
      await c.read(myMembershipsProvider.future);
      expect(c.read(currentMessIdProvider), isNull);
      expect(c.read(amIManagerProvider), isFalse);
    });
  });

  test('controller surfaces repository AppFailure', () async {
    final repo = MockMessRepository();
    when(
      () => repo.setRole('m-a', MemberRole.manager),
    ).thenThrow(const AppFailure(FailureKind.notManager, '0 rows affected'));
    final c = ProviderContainer(
      overrides: [messRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    final member = Membership.fromJson(memberRow('a')).member;
    await expectLater(
      c.read(messControllerProvider).setRole(member, MemberRole.manager),
      throwsA(
        isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.notManager),
      ),
    );
  });
}
