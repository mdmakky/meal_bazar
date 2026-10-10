import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/domain/profile.dart';
import 'package:meal_bazar/features/meals/application/meal_providers.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/data/mess_repository.dart';
import 'package:meal_bazar/features/mess/domain/invite_preview.dart';
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
  List<GoRoute> extraRoutes = const [],
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(path: '/pending', builder: (_, _) => const Text('pending-page')),
      ...extraRoutes,
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
        mealTypesProvider.overrideWith(
          (ref, id) async => const [
            MealType(
              id: 'dinner',
              messId: 'mess1',
              name: 'রাত',
              sortOrder: 2,
              weight: 1,
              enabled: true,
              serveTime: '21:00:00',
            ),
          ],
        ),
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
      expect(
        extractInviteCode('https://mealbazar.app/join/ABC1234567890'),
        isNull,
      );
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

    testWidgets('meal-only: parsed, tagged, and the switch calls the repo', (
      tester,
    ) async {
      final json = {
        'id': 'k',
        'mess_id': 'mess1',
        'display_name': 'Karim',
        'role': 'member',
        'status': 'active',
        'joined_on': '2026-10-01',
      };
      expect(Member.fromJson(json).mealOnly, false);
      expect(Member.fromJson({...json, 'meal_only': true}).mealOnly, true);

      when(
        () => repo.setMealOnly('k', true),
      ).thenAnswer((_) async => member('k', 'Karim'));
      final k = Member.fromJson({...json, 'meal_only': false});
      final sam = Member.fromJson({
        ...json,
        'id': 's',
        'display_name': 'Sam',
        'meal_only': true,
      });
      await pump(
        tester,
        const MembersScreen(),
        members: [
          member('me', 'Rahim', role: MemberRole.manager),
          k,
          sam,
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text(l.splitMemMealOnlyTag), findsOneWidget); // Sam only

      await tester.tap(find.text('Karim'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      verify(() => repo.setMealOnly('k', true)).called(1);
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

  testWidgets('invite link sheet creates a link and shows it', (tester) async {
    when(() => repo.createInvite('mess1')).thenAnswer((_) async => 'ABC123');
    when(
      () => repo.createInviteLink('mess1', inviteeName: 'Karim'),
    ).thenAnswer((_) async => 'K7MQ2XW9ZA');
    await pump(tester, const InviteScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inviteByLink')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('inviteeName')), 'Karim');
    await tester.tap(find.byKey(const Key('createLink')));
    await tester.pumpAndSettle();

    expect(
      find.text('https://meal-bazar-admin.vercel.app/join/K7MQ2XW9ZA'),
      findsOneWidget,
    );
    expect(find.text(l.inviteCopyLink), findsOneWidget);
    expect(find.text(l.inviteLinkNote), findsOneWidget);
  });

  group('JoinMessScreen invite preview', () {
    InvitePreview preview({
      bool valid = true,
      String? reason,
      bool auto = true,
      String? invitee,
    }) => InvitePreview(
      valid: valid,
      reason: reason,
      messName: 'Mirpur Mess',
      inviterName: 'Rahim',
      inviteeName: invitee,
      autoApprove: auto,
    );

    testWidgets('valid link invite joins and goes home', (tester) async {
      when(
        () => repo.invitePreview('K7MQ2XW9ZA'),
      ).thenAnswer((_) async => preview(invitee: 'Karim'));
      when(
        () => repo.joinMess(code: 'K7MQ2XW9ZA', displayName: 'Rahim'),
      ).thenAnswer((_) async => 'member-id');
      await pump(
        tester,
        const JoinMessScreen(initialCode: 'k7mq2xw9za'),
        extraRoutes: [
          GoRoute(path: '/today', builder: (_, _) => const Text('home-page')),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(l.inviteCardTitle('Rahim', 'Mirpur Mess')), findsOne);
      expect(find.text(l.inviteCardFor('Karim')), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, l.inviteJoinNow));
      await tester.pumpAndSettle();

      verify(
        () => repo.joinMess(code: 'K7MQ2XW9ZA', displayName: 'Rahim'),
      ).called(1);
      expect(find.text('home-page'), findsOneWidget);
    });

    for (final (reason, text) in [
      ('used', l.inviteReasonUsed),
      ('expired', l.inviteReasonExpired),
    ]) {
      testWidgets('$reason invite explains and keeps the code field', (
        tester,
      ) async {
        when(
          () => repo.invitePreview('K7MQ2XW9ZA'),
        ).thenAnswer((_) async => preview(valid: false, reason: reason));
        await pump(tester, const JoinMessScreen(initialCode: 'K7MQ2XW9ZA'));
        await tester.pumpAndSettle();

        expect(find.text(text), findsOneWidget);
        expect(find.byKey(const Key('inviteCode')), findsOneWidget);
        expect(find.widgetWithText(AppButton, l.inviteJoinNow), findsNothing);
      });
    }
  });

  test('InvitePreview parses the RPC row', () {
    final p = InvitePreview.fromJson({
      'valid': false,
      'reason': 'used',
      'mess_name': 'M',
      'inviter_name': 'R',
      'invitee_name': null,
      'auto_approve': true,
    });
    expect(
      (p.valid, p.reason, p.messName, p.autoApprove),
      (false, 'used', 'M', true),
    );
    expect(p.inviteeName, isNull);
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

    testWidgets('fund mode switch is saved', (tester) async {
      when(() => repo.setFundMode(any(), any())).thenAnswer((_) async {});
      await pump(tester, const MessSettingsScreen());
      await tester.pumpAndSettle();
      final sw = find.byKey(const ValueKey('fund-mode'));
      await tester.ensureVisible(sw);
      expect(tester.widget<SwitchListTile>(sw).value, isTrue);
      await tester.tap(sw);
      await tester.pumpAndSettle();
      verify(() => repo.setFundMode('mess1', false)).called(1);
    });

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
          mealOffLead: any(named: 'mealOffLead'),
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
          mealOffLead: (minutes: null),
          fixedRate: true,
          fixedMealRate: 60,
        ),
      ).called(1);
    });

    testWidgets('meal-off deadline presets, example and custom hours', (
      tester,
    ) async {
      when(
        () => repo.updateMess(
          any(),
          name: any(named: 'name'),
          address: any(named: 'address'),
          monthStartDay: any(named: 'monthStartDay'),
          mealOffCutoff: any(named: 'mealOffCutoff'),
          mealOffLead: any(named: 'mealOffLead'),
          fixedRate: any(named: 'fixedRate'),
          fixedMealRate: any(named: 'fixedMealRate'),
        ),
      ).thenAnswer((_) async => mess);
      await pump(tester, const MessSettingsScreen());
      await tester.pumpAndSettle();

      // No lead yet: the previous-day rule is selected, with its time.
      expect(find.text(l.settingsLeadTitle), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('lead--1')))
            .selected,
        isTrue,
      );
      expect(find.text(l.settingsCutoff), findsOneWidget);
      expect(
        find.text(l.settingsLeadExample('রাতের', 'গতকাল রাত ১০টা')),
        findsOneWidget,
      );

      await tester.tap(find.text(l.settingsLeadHours('২')));
      await tester.pumpAndSettle();
      expect(find.text(l.settingsCutoff), findsNothing);
      expect(
        find.text(l.settingsLeadExample('রাতের', 'সন্ধ্যা ৭টা')),
        findsOneWidget,
      );
      await save(tester);
      verify(
        () => repo.updateMess(
          'mess1',
          name: any(named: 'name'),
          address: any(named: 'address'),
          monthStartDay: any(named: 'monthStartDay'),
          mealOffCutoff: any(named: 'mealOffCutoff'),
          mealOffLead: (minutes: 120),
          fixedRate: any(named: 'fixedRate'),
          fixedMealRate: any(named: 'fixedMealRate'),
        ),
      ).called(1);

      // Custom: hours (Bangla digits too), validated 0–48.
      await tester.tap(find.text(l.settingsLeadCustom));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('lead-hours')), '৪৯');
      await save(tester);
      expect(find.text(l.settingsLeadCustomInvalid), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('lead-hours')), '০.৫');
      await tester.pumpAndSettle();
      expect(
        find.text(l.settingsLeadExample('রাতের', 'রাত ৮:৩০')),
        findsOneWidget,
      );
      await save(tester);
      verify(
        () => repo.updateMess(
          'mess1',
          name: any(named: 'name'),
          address: any(named: 'address'),
          monthStartDay: any(named: 'monthStartDay'),
          mealOffCutoff: any(named: 'mealOffCutoff'),
          mealOffLead: (minutes: 30),
          fixedRate: any(named: 'fixedRate'),
          fixedMealRate: any(named: 'fixedMealRate'),
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
          mealOffLead: any(named: 'mealOffLead'),
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
          mealOffLead: any(named: 'mealOffLead'),
          fixedRate: false,
          fixedMealRate: null,
        ),
      ).called(1);
    });
  });
}
