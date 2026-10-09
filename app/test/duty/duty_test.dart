import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/dates.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/app_button.dart';
import 'package:meal_bazar/core/widgets/app_card.dart';
import 'package:meal_bazar/features/duty/application/duty_providers.dart';
import 'package:meal_bazar/features/duty/data/duty_repository.dart';
import 'package:meal_bazar/features/duty/domain/duty.dart';
import 'package:meal_bazar/features/duty/presentation/duty_screen.dart';
import 'package:meal_bazar/features/duty/presentation/today_duty_card.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/money/application/bazar_request_providers.dart';
import 'package:meal_bazar/features/money/application/money_providers.dart';
import 'package:meal_bazar/features/money/data/bazar_request_repository.dart';
import 'package:meal_bazar/features/money/data/money_repository.dart';
import 'package:meal_bazar/features/money/domain/bazar_request.dart';
import 'package:meal_bazar/features/reminders/application/reminder_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../reminders/reminders_test.dart' show FakeNotifications;

class MockDutyRepository extends Mock implements DutyRepository {}

class MockRequests extends Mock implements BazarRequestRepository {}

class MockMoneyRepository extends Mock implements MoneyRepository {}

class FixedMess extends CurrentMessId {
  @override
  String? build() => 'mess1';
}

Member member(String id, String name, {MemberRole role = MemberRole.member}) =>
    Member(
      id: id,
      messId: 'mess1',
      displayName: name,
      role: role,
      status: MemberStatus.active,
      joinedOn: DateTime(2026),
    );

final rahim = member('m-rahim', 'রহিম', role: MemberRole.manager);
final karim = member('m-karim', 'করিম');

BazarDuty duty(
  String id,
  DateTime date,
  String memberId, {
  bool done = false,
}) => BazarDuty(
  id: id,
  messId: 'mess1',
  date: date,
  memberId: memberId,
  done: done,
);

Future<void> pump(
  WidgetTester tester,
  Widget child, {
  required MockDutyRepository repo,
  required Member me,
  List<Override> extra = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...extra,
        dutyRepositoryProvider.overrideWithValue(repo),
        currentMessIdProvider.overrideWith(FixedMess.new),
        currentMembershipProvider.overrideWithValue(Membership(member: me)),
        amIManagerProvider.overrideWithValue(me.isActiveManager),
        membersProvider('mess1').overrideWith((ref) async => [rahim, karim]),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(
      BazarRequest(id: 'x', messId: 'x', date: DateTime(2000), amount: 1),
    );
    registerFallbackValue(duty('x', DateTime(2000), 'x'));
    registerFallbackValue(
      DutyRotation(memberIds: const [], from: DateTime(2000), days: 1),
    );
  });

  test('rotation params match the RPC signature', () {
    final r = DutyRotation(
      memberIds: const ['a', 'b'],
      from: DateTime(2026, 10, 9),
      days: 14,
      every: 2,
    );
    expect(r.params('mess1'), {
      'p_mess': 'mess1',
      'p_from': '2026-10-09',
      'p_days': 14,
      'p_member_ids': ['a', 'b'],
      'p_every': 2,
    });
  });

  testWidgets('manager builds a rota: members in tap order', (tester) async {
    final repo = MockDutyRepository();
    when(() => repo.duties(any(), any(), any())).thenAnswer((_) async => []);
    when(() => repo.generate(any(), any())).thenAnswer((_) async => 30);
    await pump(tester, const DutyScreen(), repo: repo, me: rahim);

    await tester.tap(find.text('পালা বানান').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'করিম'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'রহিম'));
    await tester.pump();
    expect(find.text('১. করিম'), findsOneWidget);
    expect(find.text('২. রহিম'), findsOneWidget);
    await tester.ensureVisible(find.text('পালা বানান').last);
    await tester.tap(find.text('পালা বানান').last);
    await tester.pumpAndSettle();

    final r =
        verify(() => repo.generate('mess1', captureAny())).captured.single
            as DutyRotation;
    expect(r.params('mess1'), {
      'p_mess': 'mess1',
      'p_from': isoDate(today()),
      'p_days': 30,
      'p_member_ids': ['m-karim', 'm-rahim'],
      'p_every': 1,
    });
    expect(find.text('৩০টি পালা তৈরি হয়েছে'), findsOneWidget);
  });

  testWidgets('member ticks own duty via the RPC, not others', (tester) async {
    final repo = MockDutyRepository();
    final t = today();
    when(() => repo.duties(any(), any(), any())).thenAnswer(
      (_) async => [duty('d1', t, 'm-karim'), duty('d2', t, 'm-rahim')],
    );
    when(() => repo.markMine(any(), any())).thenAnswer((_) async {});
    await pump(tester, const DutyScreen(), repo: repo, me: karim);

    expect(find.text('পালা বানান'), findsNothing); // member: no rota button
    final mine = find.descendant(
      of: find.widgetWithText(DutyTile, 'করিম').first,
      matching: find.byType(Checkbox),
    );
    final theirs = find.descendant(
      of: find.widgetWithText(DutyTile, 'রহিম'),
      matching: find.byType(Checkbox),
    );
    expect(tester.widget<Checkbox>(theirs).onChanged, isNull);
    await tester.tap(mine);
    await tester.pumpAndSettle();
    verify(() => repo.markMine('d1', true)).called(1);
    verifyNever(() => repo.save(any()));
  });

  group('TodayDutyCard', () {
    final t = today();
    final tomorrow = DateTime(t.year, t.month, t.day + 1);

    testWidgets('my duty today offers submit and mark done', (tester) async {
      final repo = MockDutyRepository();
      when(
        () => repo.duties(any(), any(), any()),
      ).thenAnswer((_) async => [duty('d1', t, 'm-karim')]);
      when(() => repo.markMine(any(), any())).thenAnswer((_) async {});
      await pump(tester, const TodayDutyCard(), repo: repo, me: karim);

      expect(find.text('আজ আপনার বাজারের পালা'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'বাজারের হিসাব দিন'), findsOne);
      await tester.tap(find.text('বাজার করেছি'));
      await tester.pumpAndSettle();
      verify(() => repo.markMine('d1', true)).called(1);
    });

    testWidgets('done today shows done', (tester) async {
      final repo = MockDutyRepository();
      when(
        () => repo.duties(any(), any(), any()),
      ).thenAnswer((_) async => [duty('d1', t, 'm-karim', done: true)]);
      await pump(tester, const TodayDutyCard(), repo: repo, me: karim);

      expect(find.text('বাজার হয়ে গেছে'), findsOneWidget);
      expect(find.text('বাজার করেছি'), findsNothing);
    });

    testWidgets('someone else today and tomorrow', (tester) async {
      final repo = MockDutyRepository();
      when(() => repo.duties(any(), any(), any())).thenAnswer(
        (_) async => [
          duty('d1', t, 'm-rahim'),
          duty('d2', tomorrow, 'm-karim'),
        ],
      );
      await pump(tester, const TodayDutyCard(), repo: repo, me: karim);

      expect(find.text('আজ বাজার করবেন রহিম'), findsOneWidget);
      expect(find.text('কাল আপনার বাজারের পালা'), findsOneWidget);
      expect(find.text('বাজার করেছি'), findsNothing);
    });

    testWidgets('three days: today, tomorrow and the day after', (
      tester,
    ) async {
      final repo = MockDutyRepository();
      final dayAfter = DateTime(t.year, t.month, t.day + 2);
      when(() => repo.duties(any(), any(), any())).thenAnswer(
        (_) async => [
          duty('d1', t, 'm-rahim'),
          duty('d2', tomorrow, 'm-rahim'),
          duty('d3', dayAfter, 'm-karim'),
        ],
      );
      await pump(tester, const TodayDutyCard(), repo: repo, me: karim);

      verify(() => repo.duties('mess1', t, dayAfter)).called(1);
      expect(find.text('আজ বাজার করবেন রহিম'), findsOneWidget);
      expect(find.text('কাল বাজার করবেন রহিম'), findsOneWidget);
      expect(find.text('পরশু আপনার বাজারের পালা'), findsOneWidget);
      expect(find.text('বাজারের হিসাব দিন'), findsNothing);
    });

    testWidgets('submitting my bazar ticks the duty', (tester) async {
      final repo = MockDutyRepository();
      final requests = MockRequests();
      final money = MockMoneyRepository();
      when(
        () => repo.duties(any(), any(), any()),
      ).thenAnswer((_) async => [duty('d1', t, 'm-karim')]);
      when(() => repo.markMine(any(), any())).thenAnswer((_) async {});
      when(() => requests.submit(any())).thenAnswer((_) async {});
      when(() => money.itemNames(any())).thenAnswer((_) async => []);
      await pump(
        tester,
        const TodayDutyCard(),
        repo: repo,
        me: karim,
        extra: [
          bazarRequestRepositoryProvider.overrideWithValue(requests),
          moneyRepositoryProvider.overrideWithValue(money),
          monthsProvider.overrideWith((ref, id) async => const []),
        ],
      );

      await tester.tap(find.text('বাজারের হিসাব দিন'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('amount')), '320');
      final send = find.widgetWithText(AppButton, 'জমা দিন');
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();

      final r =
          verify(() => requests.submit(captureAny())).captured.single
              as BazarRequest;
      expect(r.amount, 320);
      expect(r.buyerIds, ['m-karim']);
      verify(() => repo.markMine('d1', true)).called(1);
    });

    testWidgets('nobody on duty renders nothing', (tester) async {
      final repo = MockDutyRepository();
      when(() => repo.duties(any(), any(), any())).thenAnswer((_) async => []);
      await pump(tester, const TodayDutyCard(), repo: repo, me: karim);

      expect(find.byType(AppCard), findsNothing);
    });
  });

  test('loading duties schedules reminders for my upcoming duties', () async {
    tzdata.initializeTimeZones();
    final repo = MockDutyRepository();
    when(() => repo.duties(any(), any(), any())).thenAnswer(
      (_) async => [
        duty('a', DateTime(2026, 10, 12), karim.id),
        duty('b', DateTime(2026, 10, 13), karim.id, done: true),
        duty('c', DateTime(2026, 10, 14), rahim.id),
        duty('d', DateTime(2026, 10, 8), karim.id),
      ],
    );
    final fake = FakeNotifications();
    final container = ProviderContainer(
      overrides: [
        dutyRepositoryProvider.overrideWithValue(repo),
        currentMembershipProvider.overrideWithValue(Membership(member: karim)),
        reminderServiceProvider.overrideWithValue(
          ReminderService(fake, clock: () => DateTime.utc(2026, 10, 9, 4)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(
      dutiesProvider((
        'mess1',
        DateTime(2026, 10),
        DateTime(2026, 10, 31),
      )).future,
    );
    await pumpEventQueue();
    expect(fake.scheduled.keys, [20261012]);
  });
}
