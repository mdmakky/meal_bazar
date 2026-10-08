import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/prefs.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/money/application/money_providers.dart';
import 'package:meal_bazar/features/money/data/money_repository.dart';
import 'package:meal_bazar/features/money/domain/money.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/today/presentation/setup_checklist.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

final l = lookupAppLocalizations(const Locale('bn'));

Member member(String id, {MemberStatus status = MemberStatus.active}) => Member(
  id: id,
  messId: 'mess1',
  displayName: id,
  role: MemberRole.member,
  status: status,
  joinedOn: DateTime(2026, 1, 1),
);

MonthTotals totals(double meals) => MonthTotals(
  foodTotal: 0,
  totalMeals: meals,
  mealRate: 0,
  extraTotal: 0,
  creditTotal: 0,
);

Future<void> pump(
  WidgetTester tester, {
  Set<String>? flags,
  List<Member>? members,
  bool deposit = false,
  double meals = 0,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: SingleChildScrollView(child: SetupChecklist(messId: 'mess1')),
        ),
      ),
      GoRoute(
        path: '/more/meal-types',
        builder: (_, _) => const Text('meal types screen'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (flags != null)
          messFlagsProvider.overrideWith((ref, id) async => flags),
        membersProvider.overrideWith(
          (ref, id) async => members ?? [member('a')],
        ),
        moneyRepositoryProvider.overrideWithValue(MockMoneyRepository()),
        depositsProvider.overrideWith2(
          (messId) => PagedList<Deposit>(
            messId,
            (_, _, _, _) async => [
              if (deposit)
                Deposit(
                  id: 'd',
                  messId: 'mess1',
                  memberId: 'a',
                  date: DateTime(2026, 10, 1),
                  amount: 500,
                ),
            ],
          ),
        ),
        currentPeriodProvider.overrideWith(
          (ref, id) async =>
              MonthPeriod(DateTime(2026, 10, 1), DateTime(2026, 11, 1)),
        ),
        monthTotalsProvider.overrideWith((ref, id) async => totals(meals)),
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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('progress comes from the data; one start button', (tester) async {
    await pump(
      tester,
      flags: {setupFlagMealTypes},
      members: [
        member('a'),
        member('b'),
        member('c', status: MemberStatus.pending),
      ],
    );
    expect(find.text(l.setupTitle), findsOneWidget);
    // Mess, meal types and members are done; deposit is the current step.
    expect(find.text(l.setupProgress('৩', '৫')), findsOneWidget);
    expect(find.text(l.setupStart), findsOneWidget);
    final depositRow = find.ancestor(
      of: find.text(l.setupDeposit),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(of: depositRow, matching: find.text(l.setupStart)),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.text(l.setupMembers)).style?.decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('one member is not enough; deposits and meals count', (
    tester,
  ) async {
    await pump(tester, flags: {}, deposit: true, meals: 3);
    // Mess, deposit, meals.
    expect(find.text(l.setupProgress('৩', '৫')), findsOneWidget);
  });

  testWidgets('the current step button navigates', (tester) async {
    await pump(tester, flags: {});
    await tester.tap(find.text(l.setupStart));
    await tester.pumpAndSettle();
    expect(find.text('meal types screen'), findsOneWidget);
  });

  testWidgets('hidden once every step is done', (tester) async {
    await pump(
      tester,
      flags: {setupFlagMealTypes},
      members: [member('a'), member('b')],
      deposit: true,
      meals: 1,
    );
    expect(find.text(l.setupTitle), findsNothing);
  });

  testWidgets('পরে করব hides it and the dismissal persists', (tester) async {
    await pump(tester);
    expect(find.text(l.setupTitle), findsOneWidget);

    await tester.tap(find.text(l.setupLater));
    await tester.pumpAndSettle();
    expect(find.text(l.setupTitle), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('flags:mess1'), contains(setupFlagDismissed));

    // A fresh app start reads it back.
    await tester.pumpWidget(const SizedBox());
    await pump(tester);
    expect(find.text(l.setupTitle), findsNothing);
  });
}
