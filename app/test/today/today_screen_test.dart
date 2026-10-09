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
import 'package:meal_bazar/features/recurring/application/recurring_providers.dart';
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
    expect(find.text('৩½'), findsOneWidget);
    expect(find.text('দুপুর ১½ · রাত ২ · অতিথি ১'), findsOneWidget);
    // The header's rate (the dashboard below repeats it).
    expect(find.text('৳৬৮.৭৮').first, findsOneWidget);
    // আজকের মিল: per meal type and the day total, no grid here.
    expect(find.text(l.mealGridToday), findsOneWidget);
    expect(find.text('দুপুর ১.৫ · রাত ২'), findsOneWidget);
    expect(find.text('৩.৫'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Karim দুপুর')), findsNothing);
    expect(find.text(l.todayActionBazar), findsOneWidget);
    expect(find.text(l.todayAiEntry), findsOneWidget);
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

  testWidgets('members: no quick actions or AI entry; meal-off hint', (
    tester,
  ) async {
    when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
    await pump(
      tester,
      manager: false,
      now: day.subtract(const Duration(days: 2)),
    );
    expect(find.text(l.todayActionBazar), findsNothing);
    expect(find.text(l.todayAiEntry), findsNothing);
    expect(find.text(l.mealOffHint('১০')), findsOneWidget);
  });

  testWidgets('Home: notice banner, monthly bills prompt, duty card', (
    tester,
  ) async {
    when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
    final extra = [
      latestPinnedUnreadProvider.overrideWithValue(
        Notice(
          id: 'n1',
          messId: 'mess1',
          title: 'Rent due Friday',
          createdAt: DateTime(2026),
          pinned: true,
        ),
      ),
      pendingRecurringProvider.overrideWith((ref, id) async => 2),
      dutiesProvider.overrideWith(
        (ref, k) async => [
          BazarDuty(id: 'd1', messId: 'mess1', date: day, memberId: 'karim'),
        ],
      ),
    ];
    await pump(tester, extra: extra);
    expect(find.text('Rent due Friday'), findsOneWidget);
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
        latestPinnedUnreadProvider.overrideWithValue(
          Notice(
            id: 'n1',
            messId: 'mess1',
            title: 'Rent due Friday',
            createdAt: DateTime(2026),
            pinned: true,
          ),
        ),
        pendingRecurringProvider.overrideWith((ref, id) async => 2),
        dutiesProvider.overrideWith(
          (ref, k) async => [
            BazarDuty(id: 'd1', messId: 'mess1', date: day, memberId: 'karim'),
          ],
        ),
      ],
    );
    expect(find.text(l.todayActionBazar), findsOneWidget);
    expect(find.text(l.todayAiEntry), findsNothing);
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
    expect(find.text(l.todayAiEntry), findsNothing);
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
    expect(find.text(l.syncSynced), findsOneWidget);

    await failed('mine', 'mess1');
    await tester.pumpAndSettle();
    expect(find.text(l.syncFailed), findsOneWidget);
    expect(find.text(l.failureMonthClosed), findsOneWidget);

    await tester.tap(find.text(l.syncDiscard));
    await tester.pumpAndSettle();
    expect(find.text(l.syncSynced), findsOneWidget);
    final left = await db.select(db.syncQueue).get();
    expect(left.map((o) => o.id), ['other']);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
