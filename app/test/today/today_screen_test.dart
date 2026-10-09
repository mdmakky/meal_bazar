import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/dates.dart';
import 'package:meal_bazar/core/db/db.dart';
import 'package:meal_bazar/core/format.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/duty/application/duty_providers.dart';
import 'package:meal_bazar/features/duty/domain/duty.dart';
import 'package:meal_bazar/features/meals/application/meal_providers.dart';
import 'package:meal_bazar/features/meals/data/meal_repository.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/notices/application/notice_providers.dart';
import 'package:meal_bazar/features/notices/domain/notice.dart';
import 'package:meal_bazar/features/push/application/inbox_providers.dart';
import 'package:meal_bazar/features/messages/application/message_providers.dart';
import 'package:meal_bazar/features/today/application/day_grid.dart';
import 'package:meal_bazar/features/today/presentation/today_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../platform/fixed_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMealRepository extends Mock implements MealRepository {}

final l = lookupAppLocalizations(const Locale('bn'));

const mess = Mess(
  id: 'mess1',
  name: 'Mirpur Mess',
  monthStartDay: 1,
  currency: '৳',
  mealOffCutoff: '22:00:00',
);

Member member(String id, String name, {MemberRole role = MemberRole.member}) =>
    Member(
      id: id,
      messId: 'mess1',
      displayName: name,
      role: role,
      status: MemberStatus.active,
      joinedOn: DateTime(2026, 1, 1),
    );

MealType type(String id, String name, int order) => MealType(
  id: id,
  messId: 'mess1',
  name: name,
  sortOrder: order,
  weight: 1,
  enabled: true,
);

final day = today();
MealEntry entry(String m, String t, double c, {int guests = 0}) => MealEntry(
  memberId: m,
  mealTypeId: t,
  date: day,
  count: c,
  guestCount: guests,
);

late MockMealRepository repo;

Future<void> pump(
  WidgetTester tester, {
  bool manager = true,
  DateTime? now,
  List<Override> local = const [],
  List<Override> extra = const [],
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const TodayScreen()),
      GoRoute(path: '/meals', builder: (_, _) => const Text('meals tab')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inboxUnreadCountProvider.overrideWithValue(const AsyncData(0)),
        if (local.isEmpty) mealRepositoryProvider.overrideWithValue(repo),
        ...local,
        ...extra,
        if (now != null) nowProvider.overrideWithValue(() => now),
        myMembershipsProvider.overrideWith(
          (ref) async => [
            Membership(
              member: member(
                'rahim',
                'Rahim',
                role: manager ? MemberRole.manager : MemberRole.member,
              ),
              mess: mess,
            ),
          ],
        ),
        amIManagerProvider.overrideWithValue(manager),
        membersProvider.overrideWith(
          (ref, id) async => [
            member('rahim', 'Rahim'),
            member('karim', 'Karim'),
          ],
        ),
        monthTotalsProvider.overrideWith(
          (ref, id) async => const MonthTotals(
            foodTotal: 1410,
            totalMeals: 20.5,
            mealRate: 68.78,
            extraTotal: 0,
            creditTotal: 0,
          ),
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
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(entry('x', 'x', 1));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repo = MockMealRepository();
    when(() => repo.mealTypes(any())).thenAnswer(
      (_) async => [type('lunch', 'দুপুর', 1), type('dinner', 'রাত', 2)],
    );
    when(() => repo.mealOffDeadlines(any(), any())).thenAnswer((_) async => {});
  });

  testWidgets('first viewport: date, headcount, rate, day summary, actions', (
    tester,
  ) async {
    when(() => repo.entriesForDay(any(), any())).thenAnswer(
      (_) async => [
        entry('rahim', 'lunch', 1),
        entry('rahim', 'dinner', 1, guests: 1),
        entry('karim', 'lunch', 0.5),
      ],
    );
    await pump(tester);

    expect(
      find.text(Fmt.dateLong(day, locale: 'bn', banglaDigits: true)),
      findsOneWidget,
    );
    // The statement card: the day total (once), per meal type, guests.
    expect(find.text(l.todayHeadcountLabel), findsOneWidget);
    expect(find.text('৩½'), findsOneWidget);
    expect(find.text('দুপুর ১½ · রাত ২ · অতিথি ১'), findsOneWidget);
    // The header's rate (the dashboard below repeats it).
    expect(find.text('৳৬৮.৭৮').first, findsOneWidget);
    expect(find.text(l.mealGridGoToMeals), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Karim দুপুর')), findsNothing);
    // One "+" instead of a row of quick-action tiles.
    expect(find.text(l.todayActionBazar), findsNothing);
    expect(find.text(l.todayAiEntry), findsNothing);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text(l.mealGridAddTitle), findsOneWidget);
    for (final a in [
      l.mealGridAi,
      l.todayActionBazar,
      l.todayActionExpense,
      l.todayActionDeposit,
      l.todayActionGuest,
      l.todayActionMealOff,
    ]) {
      expect(find.text(a), findsOneWidget, reason: a);
    }
  });

  testWidgets('fits a 360 dp phone at 1.3x text without overflow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 780 * 3)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    when(
      () => repo.entriesForDay(any(), any()),
    ).thenAnswer((_) async => [entry('rahim', 'lunch', 1)]);
    await pump(tester);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('মিল বসান goes to the মিল tab', (tester) async {
    when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
    await pump(tester);
    final go = find.text(l.mealGridGoToMeals);
    await tester.ensureVisible(go);
    await tester.tap(go);
    await tester.pumpAndSettle();
    expect(find.text('meals tab'), findsOneWidget);
  });

  testWidgets('members: my balance card, my meals with switches, no "+"', (
    tester,
  ) async {
    when(
      () => repo.entriesForDay(any(), any()),
    ).thenAnswer((_) async => [entry('rahim', 'lunch', 1)]);
    when(
      () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
    ).thenAnswer((_) async {});
    await pump(
      tester,
      manager: false,
      now: day.subtract(const Duration(days: 2)),
      extra: [
        memberBalancesProvider.overrideWith(
          (ref, id) async => [
            const MemberBalance(
              memberId: 'rahim',
              displayName: 'Rahim',
              meals: 12.5,
              foodCost: 859.75,
              extraCost: 0,
              credit: 500,
              openingBalance: 0,
              closingBalance: -359.75,
            ),
          ],
        ),
      ],
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text(l.todayAiEntry), findsNothing);
    expect(find.text(l.todayHeadcountLabel), findsNothing);
    expect(find.text(l.mineBalance), findsOneWidget);
    expect(find.text('-৳৩৫৯.৭৫'), findsOneWidget);
    expect(find.text('১২½'), findsOneWidget);
    // Synced is the normal state: the hero says nothing about it.
    expect(find.text('সেভ হয়েছে'), findsNothing);
    expect(find.text(l.myTodayTitle), findsOneWidget);
    // Today, then tomorrow under its own header; my count reads "১ মিল".
    expect(find.text(l.myTomorrow), findsOneWidget);
    expect(find.text(l.myMealCount('১')), findsWidgets);
    final lunch = find.byKey(ValueKey('my-${isoDate(day)}-lunch'));
    final sw = find.descendant(of: lunch, matching: find.byType(Switch));
    expect(tester.widget<Switch>(sw).value, isTrue);
    expect(tester.widget<Switch>(sw).onChanged, isNotNull);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    // Asks before turning off; cancelling saves nothing.
    expect(find.text(l.mealOffConfirmBody), findsOneWidget);
    await tester.tap(find.text(l.cancel));
    await tester.pumpAndSettle();
    verifyNever(
      () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
    );
    await tester.tap(sw);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.mealOffConfirmAction));
    await tester.pumpAndSettle();
    verify(() => repo.setMyMealOff('mess1', day, 'lunch', off: true)).called(1);
  });

  testWidgets('members: SQL deadlines per row; past one is locked', (
    tester,
  ) async {
    final tomorrow = DateTime(day.year, day.month, day.day + 1);
    // Deadlines as SQL returns them: lunch 13:00 Dhaka (07:00 UTC).
    DateTime at(DateTime d, int utcHour) =>
        DateTime.utc(d.year, d.month, d.day, utcHour);
    when(() => repo.mealOffDeadlines(any(), any())).thenAnswer((inv) async {
      final d = inv.positionalArguments[1] as DateTime;
      return {'lunch': at(d, 7), 'dinner': at(d, 13)};
    });
    when(
      () => repo.entriesForDay(any(), any()),
    ).thenAnswer((_) async => [entry('rahim', 'lunch', 1)]);
    // 15:00 Dhaka today: lunch closed, dinner open until 19:00.
    await pump(tester, manager: false, now: at(day, 9));
    await tester.pumpAndSettle();

    Switch switchOf(DateTime d, String t) => tester.widget<Switch>(
      find.descendant(
        of: find.byKey(ValueKey('my-${isoDate(d)}-$t')),
        matching: find.byType(Switch),
      ),
    );
    expect(switchOf(day, 'lunch').onChanged, isNull);
    expect(find.text(l.mealOffCutoffPassed), findsOneWidget);
    expect(switchOf(day, 'dinner').onChanged, isNotNull);
    expect(find.text(l.mealOffUntil('সন্ধ্যা ৭টা')), findsOneWidget);
    // Tomorrow's rows show tomorrow's deadlines.
    expect(switchOf(tomorrow, 'lunch').onChanged, isNotNull);
    expect(find.text(l.mealOffUntil('কাল দুপুর ১টা')), findsOneWidget);
    expect(find.text(l.mealOffUntil('কাল সন্ধ্যা ৭টা')), findsOneWidget);
  });

  testWidgets('members: card fits 360 dp at 1.3× text', (tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    when(
      () => repo.mealOffDeadlines(any(), any()),
    ).thenAnswer((_) async => {'lunch': DateTime.utc(2000)});
    when(
      () => repo.entriesForDay(any(), any()),
    ).thenAnswer((_) async => [entry('rahim', 'lunch', 1, guests: 2)]);
    await pump(tester, manager: false);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l.myTomorrow));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home: notice banner, monthly bills prompt, duty card', (
    tester,
  ) async {
    when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
    final extra = [
      homeNoticesProvider.overrideWithValue([
        Notice(
          id: 'n1',
          messId: 'mess1',
          title: 'Rent due Friday',
          createdAt: DateTime(2026),
          pinned: true,
        ),
      ]),
      attentionProvider.overrideWith(
        (ref, id) async => (
          pendingDeposits: 0,
          pendingMembers: 0,
          mealsMissing: 0,
          pendingRecurring: 2,
        ),
      ),
      dutiesProvider.overrideWith(
        (ref, k) async => [
          BazarDuty(id: 'd1', messId: 'mess1', date: day, memberId: 'karim'),
        ],
      ),
    ];
    await pump(tester, extra: extra);
    expect(find.text('Rent due Friday'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l.recurringPending('২')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l.recurringPending('২')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l.dutyTodayOther('Karim')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l.dutyTodayOther('Karim')), findsOneWidget);

    await pump(tester, manager: false, extra: extra);
    expect(find.text('Rent due Friday'), findsOneWidget);
    expect(find.text(l.recurringPending('২')), findsNothing);
  });

  testWidgets('platform flags hide AI, notices, duty and the bills prompt', (
    tester,
  ) async {
    when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
    await pump(
      tester,
      extra: [
        flagsOff(['ai_meal_draft', 'notices', 'duty', 'recurring']),
        homeNoticesProvider.overrideWithValue([
          Notice(
            id: 'n1',
            messId: 'mess1',
            title: 'Rent due Friday',
            createdAt: DateTime(2026),
            pinned: true,
          ),
        ]),
        attentionProvider.overrideWith(
          (ref, id) async => (
            pendingDeposits: 0,
            pendingMembers: 0,
            mealsMissing: 0,
            pendingRecurring: 2,
          ),
        ),
        dutiesProvider.overrideWith(
          (ref, k) async => [
            BazarDuty(id: 'd1', messId: 'mess1', date: day, memberId: 'karim'),
          ],
        ),
      ],
    );
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Rent due Friday'), findsNothing);
    expect(find.text(l.recurringPending('২')), findsNothing);
    expect(find.text(l.dutyTodayOther('Karim')), findsNothing);
  });

  testWidgets('ai master switch off hides the AI row too', (tester) async {
    when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
    await pump(
      tester,
      extra: [
        platformConfig({
          'ai': {'enabled': false},
        }),
      ],
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text(l.todayActionBazar), findsOneWidget);
    expect(find.text(l.mealGridAi), findsNothing);
  });

  testWidgets('platform banner shows on Home', (tester) async {
    when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
    await pump(
      tester,
      extra: [
        platformConfig({
          'app': {
            'banner': {
              'active': true,
              'text_bn': 'নতুন ফিচার এসেছে',
              'level': 'info',
            },
          },
        }),
      ],
    );
    expect(find.text('নতুন ফিচার এসেছে'), findsOneWidget);
  });

  testWidgets('sync badge counts this mess only; discard drops failed ops', (
    tester,
  ) async {
    final db = AppDb(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    Future<void> failed(String id, String messId) async {
      await db.enqueue('meal_entries', id, id, {'mess_id': messId});
      await db.updateOp(id, status: opFailed, lastError: 'monthClosed');
    }

    when(
      () => repo.entriesForDay(any(), any()),
    ).thenAnswer((_) async => [entry('karim', 'lunch', 1)]);
    await tester.runAsync(() => failed('other', 'mess2'));
    await pump(
      tester,
      local: [
        appDbProvider.overrideWithValue(db),
        mealRepositoryProvider.overrideWithValue(repo),
      ],
    );
    expect(find.text(l.syncFailed), findsNothing);

    await failed('mine', 'mess1');
    await tester.pumpAndSettle();
    expect(find.text(l.syncFailed), findsOneWidget);
    expect(find.text(l.failureMonthClosed), findsOneWidget);

    await tester.tap(find.text(l.syncDiscard));
    await tester.pumpAndSettle();
    expect(find.text(l.syncFailed), findsNothing);
    final left = await db.select(db.syncQueue).get();
    expect(left.map((o) => o.id), ['other']);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });

  group('message shortcuts', () {
    Override unread(int direct, bool group) => unreadSplitProvider.overrideWith(
      (ref, id) async => (direct: direct, group: group),
    );

    testWidgets('member: message manager + mess group with unread marks', (
      tester,
    ) async {
      when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
      await pump(tester, manager: false, extra: [unread(2, true)]);
      expect(find.text(l.homeMsgManager), findsOneWidget);
      expect(find.text(l.msgGroupShort), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('homeMsgShortcut')),
          matching: find.text('২'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('homeUnreadDot')), findsOneWidget);
      expect(
        find.bySemanticsLabel('${l.homeMsgManager}, ${l.homeUnreadCount('২')}'),
        findsOneWidget,
      );
    });

    testWidgets('manager: inbox + mess group; nothing unread, no marks', (
      tester,
    ) async {
      when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
      await pump(tester, extra: [unread(0, false)]);
      expect(
        find.descendant(
          of: find.byKey(const Key('homeMsgShortcut')),
          matching: find.text(l.msgTitle),
        ),
        findsOneWidget,
      );
      expect(find.text(l.homeMsgManager), findsNothing);
      expect(find.byKey(const Key('homeGroupShortcut')), findsOneWidget);
      expect(find.byKey(const Key('homeUnreadCount')), findsNothing);
      expect(find.byKey(const Key('homeUnreadDot')), findsNothing);
    });

    testWidgets('flags: mess_group off hides the group', (tester) async {
      when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
      await pump(
        tester,
        manager: false,
        extra: [
          unread(0, false),
          platformConfig({
            'features': {'mess_group': false},
          }),
        ],
      );
      expect(find.byKey(const Key('homeMsgShortcut')), findsOneWidget);
      expect(find.byKey(const Key('homeGroupShortcut')), findsNothing);
    });

    testWidgets('flags: messages off hides both', (tester) async {
      when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
      await pump(
        tester,
        manager: false,
        extra: [
          unread(0, false),
          platformConfig({
            'features': {'messages': false},
          }),
        ],
      );
      expect(find.byKey(const Key('homeMsgShortcut')), findsNothing);
      expect(find.byKey(const Key('homeGroupShortcut')), findsNothing);
    });
  });
}
