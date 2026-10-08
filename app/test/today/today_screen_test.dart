import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/dates.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/format.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/meals/application/meal_providers.dart';
import 'package:meal_bazar/features/meals/data/meal_repository.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/today/application/day_grid.dart';
import 'package:meal_bazar/features/today/presentation/today_screen.dart';
import 'package:mocktail/mocktail.dart';

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
}) async {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const TodayScreen())],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealRepositoryProvider.overrideWithValue(repo),
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
    registerFallbackValue(entry('x', 'x', 1));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repo = MockMealRepository();
    when(() => repo.mealTypes(any())).thenAnswer(
      (_) async => [type('lunch', 'দুপুর', 1), type('dinner', 'রাত', 2)],
    );
  });

  testWidgets('first viewport: date, headcount with proof, rate, grid', (
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
    expect(find.text('৳৬৮.৭৮'), findsOneWidget);
    expect(find.text('৳১,৪১০ ÷ ২০.৫ মিল'), findsOneWidget);
    expect(find.text('Karim'), findsOneWidget);
    expect(find.bySemanticsLabel('Rahim রাত: ১, +১ জন অতিথি'), findsOneWidget);
    expect(find.text(l.todayActionBazar), findsOneWidget);
    expect(find.text(l.todayAiEntry), findsOneWidget);
  });

  testWidgets('tap is optimistic and saves the cycled value', (tester) async {
    when(
      () => repo.entriesForDay(any(), any()),
    ).thenAnswer((_) async => [entry('karim', 'lunch', 0.5)]);
    final saving = Completer<void>();
    when(
      () => repo.save(any(), any(), source: any(named: 'source')),
    ).thenAnswer((_) => saving.future);
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Karim দুপুর: ½'));
    await tester.pump();
    // Shown before the server answers.
    expect(find.bySemanticsLabel('Karim দুপুর: ০'), findsOneWidget);
    final saved =
        verify(
              () => repo.save('mess1', captureAny(), source: 'app'),
            ).captured.single
            as MealEntry;
    expect(
      (saved.memberId, saved.mealTypeId, saved.count),
      ('karim', 'lunch', 0.0),
    );
    saving.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('failed save reverts the cell and explains', (tester) async {
    when(
      () => repo.entriesForDay(any(), any()),
    ).thenAnswer((_) async => [entry('karim', 'lunch', 1)]);
    when(
      () => repo.save(any(), any(), source: any(named: 'source')),
    ).thenThrow(Exception('boom'));
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Karim দুপুর: ১'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Karim দুপুর: ১'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('empty day: manager can fill', (tester) async {
    when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
    when(() => repo.fillDay(any(), any())).thenAnswer((_) async => 4);
    await pump(tester);

    await tester.tap(find.text(l.todayFill));
    await tester.pumpAndSettle();
    verify(() => repo.fillDay('mess1', day)).called(1);
  });

  testWidgets('empty day: member sees no fill action', (tester) async {
    when(() => repo.entriesForDay(any(), any())).thenAnswer((_) async => []);
    await pump(tester, manager: false);

    expect(find.text(l.todayNoEntriesMember), findsOneWidget);
    expect(find.text(l.todayFill), findsNothing);
    expect(find.text(l.todayActionBazar), findsNothing);
    expect(find.text(l.todayAiEntry), findsNothing);
  });

  testWidgets('member cells are read-only', (tester) async {
    when(
      () => repo.entriesForDay(any(), any()),
    ).thenAnswer((_) async => [entry('karim', 'lunch', 1)]);
    await pump(tester, manager: false);

    await tester.tap(find.bySemanticsLabel('Karim দুপুর: ১'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.save(any(), any(), source: any(named: 'source')));
  });

  group('member meal off', () {
    // Before today's cutoff (yesterday 22:00 Dhaka), so the clock is pinned.
    final early = day.subtract(const Duration(days: 2));

    setUp(() {
      when(
        () => repo.entriesForDay(any(), any()),
      ).thenAnswer((_) async => [entry('rahim', 'lunch', 1, guests: 1)]);
    });

    testWidgets('own row actionable, others read-only, hint shown', (
      tester,
    ) async {
      await pump(tester, manager: false, now: early);

      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Rahim দুপুর: ১, +১ জন অতিথি'),
        ),
        containsSemantics(isButton: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Karim দুপুর: ০')),
        isNot(containsSemantics(isButton: true)),
      );
      expect(find.text(l.mealOffHint('১০')), findsOneWidget);
      expect(find.text(l.mealOffTomorrow), findsOneWidget);
      expect(find.text(l.todayActionBazar), findsNothing);
    });

    testWidgets('tapping own cell calls setMyMealOff, optimistic', (
      tester,
    ) async {
      final saving = Completer<void>();
      when(
        () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
      ).thenAnswer((_) => saving.future);
      await pump(tester, manager: false, now: early);

      await tester.tap(find.bySemanticsLabel('Rahim দুপুর: ১, +১ জন অতিথি'));
      await tester.pump();
      expect(
        find.bySemanticsLabel('Rahim দুপুর: ${l.mealCellOff}, +১ জন অতিথি'),
        findsOneWidget,
      );
      verify(
        () => repo.setMyMealOff('mess1', day, 'lunch', off: true),
      ).called(1);
      verifyNever(() => repo.save(any(), any(), source: any(named: 'source')));

      await tester.tap(find.bySemanticsLabel('Karim দুপুর: ০'));
      await tester.pump();
      verifyNever(
        () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
      );
      saving.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('cutoff error reverts and explains', (tester) async {
      when(
        () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
      ).thenThrow(const AppFailure(FailureKind.cutoffPassed));
      await pump(tester, manager: false, now: early);

      await tester.tap(find.bySemanticsLabel('Rahim দুপুর: ১, +১ জন অতিথি'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Rahim দুপুর: ১, +১ জন অতিথি'),
        findsOneWidget,
      );
      expect(find.text(l.mealOffCutoffPassed), findsOneWidget);
    });

    testWidgets('after the cutoff own row is read-only', (tester) async {
      await pump(tester, manager: false);

      await tester.tap(find.bySemanticsLabel('Rahim দুপুর: ১, +১ জন অতিথি'));
      await tester.pumpAndSettle();
      verifyNever(
        () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
      );
    });

    testWidgets('quick action switches tomorrow\'s picked meals off', (
      tester,
    ) async {
      when(
        () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
      ).thenAnswer((_) async {});
      await pump(tester, manager: false, now: early);

      await tester.tap(find.text(l.mealOffTomorrow));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'রাত'));
      await tester.pump();
      await tester.tap(find.text(l.mealOffSave));
      await tester.pumpAndSettle();
      final tomorrow = dayOnly(day.add(const Duration(days: 1, hours: 2)));
      verify(
        () => repo.setMyMealOff('mess1', tomorrow, 'dinner', off: true),
      ).called(1);
      verifyNever(
        () => repo.setMyMealOff(any(), any(), 'lunch', off: any(named: 'off')),
      );
      expect(find.text(l.mealOffSaved), findsOneWidget);
    });

    testWidgets('manager keeps direct edits, no member hint', (tester) async {
      when(
        () => repo.save(any(), any(), source: any(named: 'source')),
      ).thenAnswer((_) async {});
      await pump(tester, now: early);

      expect(find.text(l.mealOffHint('১০')), findsNothing);
      await tester.tap(find.bySemanticsLabel('Rahim দুপুর: ১, +১ জন অতিথি'));
      await tester.pumpAndSettle();
      verify(() => repo.save('mess1', any(), source: 'app')).called(1);
      verifyNever(
        () => repo.setMyMealOff(any(), any(), any(), off: any(named: 'off')),
      );
    });
  });
}
