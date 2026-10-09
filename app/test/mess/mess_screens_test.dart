import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/domain/profile.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/data/mess_repository.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/mess/presentation/mess_screens.dart';
import 'package:mocktail/mocktail.dart';

class MockMessRepository extends Mock implements MessRepository {}

class FakeProfile extends MyProfileNotifier {
  @override
  Future<Profile?> build() async =>
      const Profile(id: 'u1', fullName: 'Rahim', locale: 'bn');
}

final l = lookupAppLocalizations(const Locale('bn'));

const mess = Mess(
  id: 'mess1',
  name: 'Mirpur Mess',
  monthStartDay: 1,
  currency: '৳',
  mealOffCutoff: '22:00:00',
);

Member member(
  String id,
  String name, {
  MemberRole role = MemberRole.member,
  MemberStatus status = MemberStatus.active,
}) => Member(
  id: id,
  messId: 'mess1',
  displayName: name,
  role: role,
  status: status,
  joinedOn: DateTime(2026, 10, 1),
  userId: 'user-$id',
);

late MockMessRepository repo;

Future<void> pump(
  WidgetTester tester,
  Widget screen, {
  bool manager = true,
  List<Member> members = const [],
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(path: '/pending', builder: (_, _) => const Text('pending-page')),
    ],
  );
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        messRepositoryProvider.overrideWithValue(repo),
        myProfileProvider.overrideWith(FakeProfile.new),
        myMembershipsProvider.overrideWith(
          (ref) async => [
            Membership(
              member: member(
                'me',
                'Rahim',
                role: manager ? MemberRole.manager : MemberRole.member,
              ),
              mess: mess,
            ),
          ],
        ),
        amIManagerProvider.overrideWithValue(manager),
        membersProvider.overrideWith((ref, id) async => members),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(member('x', 'x')));
  setUp(() => repo = MockMessRepository());

  group('extractInviteCode', () {
    test('reads the code from a join link', () {
      expect(extractInviteCode('https://mealbazar.app/join/ab12cd'), 'AB12CD');
      expect(
        extractInviteCode(' https://mealbazar.app/join/AB12CD?x=1 '),
        'AB12CD',
      );
    });
    test('accepts a raw code', () {
      expect(extractInviteCode('xy34zw'), 'XY34ZW');
    });
    test('rejects garbage', () {
      expect(extractInviteCode(''), isNull);
      expect(extractInviteCode('hello world'), isNull);
      expect(extractInviteCode('ABC12'), isNull);
      expect(extractInviteCode('https://mealbazar.app/join/ABC1234'), isNull);
      expect(extractInviteCode('https://example.com/other/ABC123'), isNull);
    });
  });

  group('MembersScreen', () {
    final list = [
      member('me', 'Rahim', role: MemberRole.manager),
      member('k', 'Karim', status: MemberStatus.pending),
    ];

    testWidgets('manager sees pending requests and can approve', (
      tester,
    ) async {
      when(
        () => repo.approveMember('k'),
      ).thenAnswer((_) async => member('k', 'Karim'));
      await pump(tester, const MembersScreen(), members: list);
      await tester.pumpAndSettle();

      expect(find.textContaining(l.membersPending), findsOneWidget);
      expect(find.text('Karim'), findsOneWidget);
      expect(find.text(l.membersRoleManager), findsOneWidget);

      await tester.tap(find.text(l.membersApprove));
      await tester.pumpAndSettle();
      verify(() => repo.approveMember('k')).called(1);
      expect(find.text(l.membersApproved('Karim')), findsOneWidget);
    });

    testWidgets('member does not see pending requests', (tester) async {
      await pump(tester, const MembersScreen(), manager: false, members: list);
      await tester.pumpAndSettle();

      expect(find.textContaining(l.membersPending), findsNothing);
      expect(find.text(l.membersApprove), findsNothing);
      expect(find.text('Karim'), findsNothing);
      expect(find.text(l.membersAdd), findsNothing);
    });
  });

  testWidgets('InviteScreen shows the generated code', (tester) async {
    when(() => repo.createInvite('mess1')).thenAnswer((_) async => 'ABC123');
    await pump(tester, const InviteScreen());
    await tester.pumpAndSettle();

    verify(() => repo.createInvite('mess1')).called(1);
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text(l.inviteValidity), findsOneWidget);
  });

  group('JoinMessScreen', () {
    final codeField = find.byKey(const Key('inviteCode'));
    String codeText(WidgetTester t) => t
        .widget<EditableText>(
          find.descendant(of: codeField, matching: find.byType(EditableText)),
        )
        .controller
        .text;

    testWidgets('uppercases the code and rejects short codes', (tester) async {
      await pump(tester, const JoinMessScreen());
      await tester.pumpAndSettle();

      await tester.enterText(codeField, 'ab-1 2c');
      expect(codeText(tester), 'AB12C');

      await tester.tap(find.text(l.messJoinSubmit));
      await tester.pump();
      expect(find.text(l.messCodeInvalid), findsOneWidget);
      verifyNever(
        () => repo.joinMess(
          code: any(named: 'code'),
          displayName: any(named: 'displayName'),
        ),
      );
    });

    testWidgets('valid code with prefilled name joins and goes to pending', (
      tester,
    ) async {
      when(
        () => repo.joinMess(code: 'AB12CD', displayName: 'Rahim'),
      ).thenAnswer((_) async => 'member-id');
      await pump(tester, const JoinMessScreen(initialCode: 'ab12cd'));
      await tester.pumpAndSettle();

      expect(codeText(tester), 'AB12CD');
      await tester.tap(find.text(l.messJoinSubmit));
      await tester.pumpAndSettle();

      verify(
        () => repo.joinMess(code: 'AB12CD', displayName: 'Rahim'),
      ).called(1);
      expect(find.text('pending-page'), findsOneWidget);
    });
  });

  group('MessSettingsScreen meal rate', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(800, 3000);
      view.devicePixelRatio = 1;
      addTearDown(view.reset);
    });

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(find.text(l.settingsSave));
      await tester.tap(find.text(l.settingsSave));
      await tester.pumpAndSettle();
    }

    testWidgets('fixed rate needs an amount, then sends mode and rate', (
      tester,
    ) async {
      when(
        () => repo.updateMess(
          any(),
          name: any(named: 'name'),
          address: any(named: 'address'),
          monthStartDay: any(named: 'monthStartDay'),
          mealOffCutoff: any(named: 'mealOffCutoff'),
          fixedRate: any(named: 'fixedRate'),
          fixedMealRate: any(named: 'fixedMealRate'),
        ),
      ).thenAnswer((_) async => mess);
      await pump(tester, const MessSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text(l.rateSection), findsOneWidget);
      expect(find.text(l.rateAmountLabel), findsNothing);
      await tester.tap(find.text(l.rateFixed));
      await tester.pumpAndSettle();
      await save(tester);
      expect(find.text(l.rateAmountRequired), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, l.rateAmountLabel),
        '৬০',
      );
      await save(tester);
      verify(
        () => repo.updateMess(
          'mess1',
          name: 'Mirpur Mess',
          address: '',
          monthStartDay: 1,
          mealOffCutoff: '22:00:00',
          fixedRate: true,
          fixedMealRate: 60,
        ),
      ).called(1);
    });

    testWidgets('calculated mode sends no rate', (tester) async {
      when(
        () => repo.updateMess(
          any(),
          name: any(named: 'name'),
          address: any(named: 'address'),
          monthStartDay: any(named: 'monthStartDay'),
          mealOffCutoff: any(named: 'mealOffCutoff'),
          fixedRate: any(named: 'fixedRate'),
          fixedMealRate: any(named: 'fixedMealRate'),
        ),
      ).thenAnswer((_) async => mess);
      await pump(tester, const MessSettingsScreen());
      await tester.pumpAndSettle();
      await save(tester);
      verify(
        () => repo.updateMess(
          'mess1',
          name: any(named: 'name'),
          address: any(named: 'address'),
          monthStartDay: any(named: 'monthStartDay'),
          mealOffCutoff: any(named: 'mealOffCutoff'),
          fixedRate: false,
          fixedMealRate: null,
        ),
      ).called(1);
    });
  });
}
