import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:meal_bazar/core/dates.dart';
import 'package:meal_bazar/core/db/db.dart';
import 'package:meal_bazar/core/db/sync.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/format.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/meals/application/meal_providers.dart';
import 'package:meal_bazar/features/meals/data/meal_repository.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/meals/presentation/meals_screen.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/today/application/day_grid.dart';
import 'package:meal_bazar/features/recurring/application/recurring_providers.dart';
import 'package:meal_bazar/features/recurring/domain/recurring.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, SupabaseClient;

class MockMealRepository extends Mock implements MealRepository {}

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
  DateTime? joined,
}) => Member(
  id: id,
  messId: 'mess1',
  displayName: name,
  role: role,
  status: MemberStatus.active,
  joinedOn: joined ?? DateTime(2026, 1, 1),
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
final yesterday = dayOnly(day.subtract(const Duration(hours: 22)));
MealEntry entry(String m, String t, double c, {int guests = 0, DateTime? on}) =>
    MealEntry(
      memberId: m,
      mealTypeId: t,
      date: on ?? day,
      count: c,
      guestCount: guests,
    );

final period = MonthPeriod(
  DateTime(day.year, day.month),
  DateTime(day.year, day.month + 1),
);
const totals = MonthTotals(
  foodTotal: 1410,
  totalMeals: 20.5,
  mealRate: 68.78,
  extraTotal: 0,
  creditTotal: 0,
);
const balances = [
  MemberBalance(
    memberId: 'karim',
    displayName: 'Karim',
    meals: 8.5,
    foodCost: 584.63,
    extraCost: 0,
    credit: 0,
    openingBalance: 0,
    closingBalance: -584.63,
  ),
];

late MockMealRepository repo;

/// Member default meals (meal_defaults) served to the grid.
var defaults = <MealDefaultKey, double>{};

Future<void> pump(
  WidgetTester tester, {
  bool manager = true,
  DateTime? now,
  List<Member>? members,
  List<Override> local = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const MealsScreen())],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (local.isEmpty) mealRepositoryProvider.overrideWithValue(repo),
        ...local,
        if (now != null) nowProvider.overrideWithValue(() => now),
        myMembershipsProvider.overrideWith(
          (ref) async => [
            Membership(
              member: manager
                  ? member('rahim', 'Rahim', role: MemberRole.manager)
                  : member('rahim', 'Rahim'),
              mess: mess,
            ),
          ],
        ),
        amIManagerProvider.overrideWithValue(manager),
        mealDefaultsProvider.overrideWith((ref, id) async => defaults),
        membersProvider.overrideWith(
          (ref, id) async =>
              members ??
              [
                member('rahim', 'Rahim', role: MemberRole.manager),
                member('karim', 'Karim'),
              ],
        ),
        currentPeriodProvider.overrideWith((ref, id) async => period),
        guestMealsProvider.overrideWith((ref, id) async => const {}),
        periodSummaryProvider.overrideWith(
          (ref, k) async => (period, totals, balances),
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

Finder cell(String label) => find.bySemanticsLabel(label);

MealEntry savedOne() =>
    verify(() => repo.save('mess1', captureAny(), source: 'app')).captured.last
        as MealEntry;

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    registerFallbackValue(entry('x', 'x', 1));
    registerFallbackValue(<MealEntry>[]);
    registerFallbackValue(DateTime(2026));
  });

  /// What the "server" holds per day; saves land here, refetches read it.
  late Map<DateTime, Map<String, MealEntry>> store;

  void put(MealEntry e) =>
      (store[e.date] ??= {})['${e.memberId}|${e.mealTypeId}'] = e;

  setUp(() {
    repo = MockMealRepository();
    store = {};
    defaults = {};
    when(() => repo.mealTypes(any())).thenAnswer(
      (_) async => [type('lunch', 'দুপুর', 1), type('dinner', 'রাত', 2)],
    );
    when(
      () => repo.entriesForDay(any(), any()),
    ).thenAnswer((i) async => [...?store[i.positionalArguments[1]]?.values]);
    when(
      () => repo.save(any(), any(), source: any(named: 'source')),
    ).thenAnswer((i) async => put(i.positionalArguments[1] as MealEntry));
    when(
      () => repo.saveAll(any(), any(), source: any(named: 'source')),
    ).thenAnswer(
      (i) async => (i.positionalArguments[1] as List<MealEntry>).forEach(put),
    );
  });

  void stubDay(List<MealEntry> today, [List<MealEntry> before = const []]) {
    today.forEach(put);
    before.forEach(put);
  }

  testWidgets('header, grid with decimals, column totals, day total', (
    tester,
  ) async {
    stubDay([
      entry('rahim', 'lunch', 1),
      entry('rahim', 'dinner', 1, guests: 1),
      entry('karim', 'lunch', 0.5),
    ]);
    await pump(tester);

    expect(find.text('Mirpur Mess'), findsOneWidget);
    expect(find.byTooltip(l.cookShare), findsOneWidget);
    expect(find.text(l.mealGridManager('Rahim')), findsOneWidget);
    final long = Fmt.dateLong(day, locale: 'bn', banglaDigits: true);
    expect(find.text(long.substring(long.indexOf(' ') + 1)), findsOneWidget);
    expect(find.text(long), findsOneWidget);
    expect(cell('Karim দুপুর: ০.৫'), findsOneWidget);
    expect(cell('Rahim রাত: ১, +১ জন অতিথি'), findsOneWidget);
    expect(find.text('+১'), findsOneWidget);
    // Column totals: lunch 1.5, dinner 1 + 1 guest.
    expect(find.text(l.mealGridTotalRow), findsOneWidget);
    expect(find.text('১.৫'), findsOneWidget);
    expect(find.text('২'), findsOneWidget);
    expect(find.text(l.mealGridDayTotal), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('day-total'))).data, '৩.৫');
    expect(find.text(l.mealGridHint), findsOneWidget);
    // The month summary below.
    expect(find.text(l.mealsByMember), findsOneWidget);
    expect(find.text('৮.৫'), findsOneWidget);
  });

  testWidgets('3 meal types on a 360 dp phone: names pinned, meals scroll', (
    tester,
  ) async {
    when(() => repo.mealTypes(any())).thenAnswer(
      (_) async => [
        type('breakfast', 'সকাল', 0),
        type('lunch', 'দুপুর', 1),
        type('dinner', 'রাত', 2),
      ],
    );
    stubDay([entry('karim', 'dinner', 1)]);
    await pump(tester);
    expect(tester.takeException(), isNull);
    final scroller = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    expect(scroller, findsOneWidget);
    expect(find.text('সকাল'), findsOneWidget);
    // The −/+ hit area stays ≥ 40 dp.
    final plus = tester.getSize(cell('${l.mealCellIncrease} Karim সকাল'));
    expect(plus.width, greaterThanOrEqualTo(40));
    expect(plus.height, greaterThanOrEqualTo(48));
  });

  testWidgets('value tap cycles 0 → 0.5 → 1 → 1.5 → 2 → 0, optimistic', (
    tester,
  ) async {
    stubDay([]);
    final saving = Completer<void>();
    when(
      () => repo.save(any(), any(), source: any(named: 'source')),
    ).thenAnswer((_) => saving.future);
    await pump(tester);

    await tester.tap(cell('Karim দুপুর: ০'));
    await tester.pump();
    // Shown before the server answers.
    expect(cell('Karim দুপুর: ০.৫'), findsOneWidget);
    final first = savedOne();
    expect(
      (first.memberId, first.mealTypeId, first.count),
      ('karim', 'lunch', 0.5),
    );
    put(first);
    saving.complete();
    await tester.pumpAndSettle();
    when(
      () => repo.save(any(), any(), source: any(named: 'source')),
    ).thenAnswer((i) async => put(i.positionalArguments[1] as MealEntry));

    for (final next in ['১', '১.৫', '২', '০']) {
      await tester.tap(find.bySemanticsLabel(RegExp('^Karim দুপুর: ')));
      await tester.pumpAndSettle();
      expect(cell('Karim দুপুর: $next'), findsOneWidget);
    }
  });

  testWidgets('− and + step by 0.5 and save', (tester) async {
    stubDay([entry('karim', 'lunch', 1)]);
    await pump(tester);

    await tester.tap(cell('${l.mealCellIncrease} Karim দুপুর'));
    await tester.pump();
    expect(cell('Karim দুপুর: ১.৫'), findsOneWidget);
    expect(savedOne().count, 1.5);
    await tester.pumpAndSettle();

    await tester.tap(cell('${l.mealCellDecrease} Karim দুপুর'));
    await tester.tap(cell('${l.mealCellDecrease} Karim দুপুর'));
    await tester.pumpAndSettle();
    expect(cell('Karim দুপুর: ০.৫'), findsOneWidget);
  });

  testWidgets('failed save reverts the cell and explains', (tester) async {
    stubDay([entry('karim', 'lunch', 1)]);
    when(
      () => repo.save(any(), any(), source: any(named: 'source')),
    ).thenThrow(Exception('boom'));
    await pump(tester);

    await tester.tap(cell('Karim দুপুর: ১'));
    await tester.pumpAndSettle();
    expect(cell('Karim দুপুর: ১'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('সবাই ১ sets every present member × meal to 1 in one write', (
    tester,
  ) async {
    stubDay([entry('karim', 'lunch', 0.5), entry('rahim', 'lunch', 1)]);
    await pump(tester);

    await tester.tap(find.text(l.mealGridAllOne));
    await tester.pumpAndSettle();
    final saved =
        verify(
              () => repo.saveAll('mess1', captureAny(), source: 'app'),
            ).captured.single
            as List<MealEntry>;
    // Rahim's lunch was already 1: not rewritten.
    expect(saved, hasLength(3));
    expect(saved.every((e) => e.count == 1 && !e.isOff), isTrue);
    expect(tester.widget<Text>(find.byKey(const Key('day-total'))).data, '৪');
  });

  testWidgets('গতকালের মতো: yesterday, else default, else 1', (tester) async {
    defaults = {(memberId: 'karim', mealTypeId: 'dinner'): 1.5};
    stubDay(
      [entry('karim', 'lunch', 1)],
      [
        entry('rahim', 'lunch', 2, on: yesterday),
        entry('karim', 'lunch', 1, on: yesterday),
      ],
    );
    await pump(tester);

    await tester.tap(find.text(l.mealGridLikeYesterday));
    await tester.pumpAndSettle();
    final saved =
        verify(
              () => repo.saveAll('mess1', captureAny(), source: 'app'),
            ).captured.single
            as List<MealEntry>;
    expect(
      {for (final e in saved) '${e.memberId}|${e.mealTypeId}': e.count},
      {'rahim|lunch': 2, 'rahim|dinner': 1, 'karim|dinner': 1.5},
    );
    expect(saved.every((e) => e.date == day), isTrue);
    expect(cell('Rahim দুপুর: ২'), findsOneWidget);
  });

  testWidgets('members: read-only, no steppers, bulk actions or FAB', (
    tester,
  ) async {
    stubDay([entry('karim', 'lunch', 1)]);
    await pump(tester, manager: false);

    expect(cell('${l.mealCellIncrease} Karim দুপুর'), findsNothing);
    expect(find.text(l.mealGridAllOne), findsNothing);
    expect(find.byTooltip(l.cookShare), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(cell('Karim দুপুর: ১'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.save(any(), any(), source: any(named: 'source')));
  });

  group('member meal off', () {
    // Before today's cutoff (yesterday 22:00 Dhaka), so the clock is pinned.
    final early = day.subtract(const Duration(days: 2));

    setUp(() => stubDay([entry('rahim', 'lunch', 1, guests: 1)]));

    testWidgets('own row toggles off via setMyMealOff, others read-only', (
      tester,
    ) async {
      final saving = Completer<void>();
      when(
        () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
      ).thenAnswer((_) => saving.future);
      await pump(tester, manager: false, now: early);

      expect(
        tester.getSemantics(cell('Rahim দুপুর: ১, +১ জন অতিথি')),
        containsSemantics(isButton: true),
      );
      expect(
        tester.getSemantics(cell('Karim দুপুর: ০')),
        isNot(containsSemantics(isButton: true)),
      );
      expect(find.text(l.mealOffHint('১০')), findsOneWidget);

      await tester.tap(cell('Rahim দুপুর: ১, +১ জন অতিথি'));
      await tester.pump();
      expect(
        cell('Rahim দুপুর: ${l.mealCellOff}, +১ জন অতিথি'),
        findsOneWidget,
      );
      verify(
        () => repo.setMyMealOff('mess1', day, 'lunch', off: true),
      ).called(1);
      saving.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('cutoff error reverts and explains', (tester) async {
      when(
        () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
      ).thenThrow(const AppFailure(FailureKind.cutoffPassed));
      await pump(tester, manager: false, now: early);

      await tester.tap(cell('Rahim দুপুর: ১, +১ জন অতিথি'));
      await tester.pumpAndSettle();
      expect(cell('Rahim দুপুর: ১, +১ জন অতিথি'), findsOneWidget);
      expect(find.text(l.mealOffCutoffPassed), findsOneWidget);
    });

    testWidgets('after the cutoff own row is read-only', (tester) async {
      await pump(tester, manager: false);
      await tester.tap(cell('Rahim দুপুর: ১, +১ জন অতিথি'));
      await tester.pumpAndSettle();
      verifyNever(
        () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
      );
    });
  });

  testWidgets('FAB offers AI, bazar, expense, deposit, guest', (tester) async {
    stubDay([]);
    await pump(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text(l.mealGridAddTitle), findsOneWidget);
    for (final s in [
      l.mealGridAi,
      l.todayActionBazar,
      l.todayActionExpense,
      l.todayActionDeposit,
      l.todayActionGuest,
    ]) {
      expect(find.text(s), findsOneWidget);
    }
  });

  testWidgets('a day before anyone joined says nobody was here', (
    tester,
  ) async {
    stubDay([]);
    await pump(
      tester,
      members: [
        member('rahim', 'Rahim', role: MemberRole.manager, joined: day),
      ],
    );
    expect(find.text(l.dashNobodyThatDay), findsNothing);

    await tester.tap(find.byTooltip(l.todayPrevDay));
    await tester.pumpAndSettle();
    expect(find.text(l.dashNobodyThatDay), findsOneWidget);
    expect(find.text(l.todayNoMembers), findsNothing);

    await tester.tap(find.text(l.todayBackToToday).last);
    await tester.pumpAndSettle();
    expect(find.text(l.dashNobodyThatDay), findsNothing);
  });

  testWidgets('month pill: previous month jumps to its first day', (
    tester,
  ) async {
    stubDay([]);
    await pump(tester);
    await tester.tap(find.byTooltip(l.mealGridPrevMonth));
    await tester.pumpAndSettle();
    final first = DateTime(day.year, day.month - 1);
    expect(
      find.text(Fmt.dateLong(first, locale: 'bn', banglaDigits: true)),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right).first,
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('offline: renders from Drift, saves locally, says so', (
    tester,
  ) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDb(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final sync = SyncService(db, (_, _) async {
      throw const SocketException('offline');
    });
    final offline = SupabaseClient(
      'http://localhost',
      'anon',
      httpClient: MockClient((_) async => throw const SocketException('x')),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    // What an earlier online session left behind.
    await tester.runAsync(
      () => db.cachedRows(
        'meal_types:mess1',
        () async => [
          for (final (i, n) in ['lunch', 'dinner'].indexed)
            {
              'id': n,
              'mess_id': 'mess1',
              'name': n == 'lunch' ? 'দুপুর' : 'রাত',
              'sort_order': i,
              'weight': 1,
              'enabled': true,
            },
        ],
      ),
    );
    await tester.runAsync(
      () => db
          .into(db.mealEntries)
          .insert(
            MealEntriesCompanion.insert(
              id: 'e1',
              messId: 'mess1',
              memberId: 'karim',
              mealTypeId: 'lunch',
              date: isoDate(day),
              count: 1,
              guestCount: 0,
              isOff: false,
              updatedAt: DateTime.now(),
            ),
          ),
    );

    await pump(
      tester,
      local: [
        appDbProvider.overrideWithValue(db),
        syncServiceProvider.overrideWithValue(sync),
        mealRepositoryProvider.overrideWithValue(
          MealRepository(offline, db, sync),
        ),
      ],
    );
    expect(find.text(l.syncSynced), findsOneWidget);
    expect(cell('Karim দুপুর: ১'), findsOneWidget);

    await tester.tap(cell('Karim দুপুর: ১'));
    await tester.pumpAndSettle();
    expect(cell('Karim দুপুর: ১.৫'), findsOneWidget);
    expect(find.text(l.syncOffline), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    final local = await tester.runAsync(
      () => db.select(db.mealEntries).getSingle(),
    );
    expect(local!.count, 1.5);

    sync.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
