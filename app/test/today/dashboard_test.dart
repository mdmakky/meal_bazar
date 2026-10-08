import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/dates.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';
import 'package:meal_bazar/features/meals/application/meal_providers.dart';
import 'package:meal_bazar/features/meals/data/meal_repository.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/money/application/money_providers.dart';
import 'package:meal_bazar/features/money/data/money_repository.dart';
import 'package:meal_bazar/features/money/domain/money.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/today/presentation/dashboard.dart';
import 'package:meal_bazar/features/today/presentation/today_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockMealRepository extends Mock implements MealRepository {}

class MockMoneyRepository extends Mock implements MoneyRepository {}

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
  MemberStatus status = MemberStatus.active,
  MemberRole role = MemberRole.member,
  DateTime? joined,
}) => Member(
  id: id,
  messId: 'mess1',
  displayName: name,
  role: role,
  status: status,
  joinedOn: joined ?? DateTime(2026, 1, 1),
);

MemberBalance balance(String id, String name, double closing) => MemberBalance(
  memberId: id,
  displayName: name,
  meals: 10,
  foodCost: 687.80,
  extraCost: 250,
  credit: 1500,
  openingBalance: 0,
  closingBalance: closing,
);

const totals = MonthTotals(
  foodTotal: 1710,
  totalMeals: 20.5,
  mealRate: 83.41,
  extraTotal: 500,
  creditTotal: 3000,
);

final now = today();
final period = MonthPeriod(
  DateTime(now.year, now.month),
  DateTime(now.year, now.month + 1),
);

List<DayMeals> days({bool empty = false}) => [
  for (
    var d = period.start;
    d.isBefore(period.end);
    d = d.add(const Duration(days: 1, hours: 2))
  )
    (
      date: dayOnly(d),
      meals: empty || d.isAfter(now) ? 0.0 : (d.day % 3) + 4.0,
    ),
];

Bazar bazar(int i) => Bazar(
  id: 'b$i',
  messId: 'mess1',
  date: now,
  amount: 100.0 + i,
  buyerMemberId: 'karim',
);

List<Override> overrides({
  bool manager = true,
  bool emptyCharts = false,
  bool failDaily = false,
  List<Member>? members,
}) => [
  myMembershipsProvider.overrideWith(
    (ref) async => [
      Membership(
        member: manager
            ? member('rahim', 'Rahim', role: MemberRole.manager)
            : member('karim', 'Karim'),
        mess: mess,
      ),
    ],
  ),
  amIManagerProvider.overrideWithValue(manager),
  membersProvider.overrideWith(
    (ref, id) async =>
        members ??
        [
          member('rahim', 'Rahim', role: MemberRole.manager),
          member('karim', 'Karim'),
          member('selim', 'Selim'),
          member('new', 'Nobin', status: MemberStatus.pending),
        ],
  ),
  currentPeriodProvider.overrideWith((ref, id) async => period),
  monthTotalsProvider.overrideWith((ref, id) async => totals),
  memberBalancesProvider.overrideWith(
    (ref, id) async => [
      balance('rahim', 'Rahim', 424.63),
      balance('selim', 'Selim', -100),
      balance('karim', 'Karim', -834.63),
    ],
  ),
  spendingByCategoryProvider.overrideWith(
    (ref, id) async => emptyCharts
        ? const <CategoryTotal>[]
        : const [
            (category: 'বাজার', total: 1410.0, isBazar: true),
            (category: 'ওয়াইফাই', total: 500.0, isBazar: false),
          ],
  ),
  dailyMealsProvider.overrideWith(
    (ref, id) async => failDaily
        ? throw const AppFailure(FailureKind.network)
        : days(empty: emptyCharts),
  ),
  monthHistoryProvider.overrideWith(
    (ref, id) async => [
      for (var i = 5; i >= 0; i--)
        (
          start: DateTime(now.year, now.month - i),
          foodTotal: 1000.0,
          extraTotal: 0.0,
          mealRate: emptyCharts ? 0.0 : 60.0 + i,
        ),
    ],
  ),
  moneyRepositoryProvider.overrideWithValue(MockMoneyRepository()),
  bazarsProvider.overrideWith2(
    (messId) => PagedList<Bazar>(
      messId,
      (_, _, _, _) async => [for (var i = 1; i <= 6; i++) bazar(i)],
    ),
  ),
];

Widget app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('bn'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<void> pumpDashboard(
  WidgetTester tester, {
  bool manager = true,
  bool emptyCharts = false,
  bool failDaily = false,
}) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides(
        manager: manager,
        emptyCharts: emptyCharts,
        failDaily: failDaily,
      ),
      child: app(MonthDashboard(messId: 'mess1', manager: manager)),
    ),
  );
  await tester.pumpAndSettle();
}

Finder inFigure(String text) =>
    find.descendant(of: find.byType(Figure), matching: find.text(text));

void main() {
  group('manager', () {
    testWidgets('stat block shows SQL figures with proofs', (tester) async {
      await pumpDashboard(tester);
      expect(find.text(l.dashTitle), findsOneWidget);
      // 3 active, 1 pending.
      expect(inFigure('৩'), findsOneWidget);
      expect(find.text(l.dashMembersPending('১')), findsOneWidget);
      expect(inFigure('৳৮৩.৪১'), findsOneWidget);
      expect(find.text(l.moneyMealRateProof('৳১,৭১০', '২০.৫')), findsOneWidget);
      // Bazar from the SQL bazar row, not food_total.
      expect(inFigure('৳১,৪১০'), findsOneWidget);
      expect(find.text(l.dashBazarProof('৳১,৭১০')), findsOneWidget);
      expect(inFigure('৳৫০০'), findsOneWidget);
      expect(find.text(l.dashExtraProof('৳২,২১০')), findsOneWidget);
      expect(inFigure('৳৩,০০০'), findsOneWidget);
      expect(inFigure('২০½'), findsOneWidget);
      // Dues = Σ negative closings (red); advances = Σ positive (green).
      expect(inFigure('৳৯৩৪.৬৩'), findsOneWidget);
      expect(find.text(l.dashDuesProof('২')), findsOneWidget);
      expect(inFigure('৳৪২৪.৬৩'), findsOneWidget);
      expect(find.text(l.dashAdvancesProof('১')), findsOneWidget);
      final p = AppPalette.light;
      expect(tester.widget<Text>(inFigure('৳৯৩৪.৬৩')).style?.color, p.due);
      expect(tester.widget<Text>(inFigure('৳৪২৪.৬৩')).style?.color, p.advance);
    });

    testWidgets('dues list: biggest due first; tap explains the bill', (
      tester,
    ) async {
      await pumpDashboard(tester);
      expect(find.text(l.dashWhoOwes), findsOneWidget);
      double y(String id) => tester.getTopLeft(find.byKey(ValueKey(id))).dy;
      expect(y('due-karim'), lessThan(y('due-selim')));
      expect(y('due-selim'), lessThan(y('due-rahim')));

      await tester.tap(find.byKey(const ValueKey('due-karim')));
      await tester.pumpAndSettle();
      expect(find.text(l.balanceExplainTitle('Karim')), findsOneWidget);
    });
  });

  group('member', () {
    testWidgets('members get meal-off and my-deposit buttons; managers not', (
      tester,
    ) async {
      await pumpDashboard(tester, manager: false);
      expect(find.widgetWithText(AppButton, l.mealOffTomorrow), findsOne);
      expect(find.widgetWithText(AppButton, l.depositVerifyMine), findsOne);

      await pumpDashboard(tester);
      expect(find.widgetWithText(AppButton, l.mealOffTomorrow), findsNothing);
      expect(find.widgetWithText(AppButton, l.depositVerifyMine), findsNothing);
    });

    testWidgets('my-deposit button opens the member deposit sheet', (
      tester,
    ) async {
      await pumpDashboard(tester, manager: false);
      await tester.tap(find.widgetWithText(AppButton, l.depositVerifyMine));
      await tester.pumpAndSettle();
      expect(find.text(l.depositVerifyHelp), findsOneWidget);
    });

    testWidgets('আমার হিসাব: my figures, explain sheet, recent bazar', (
      tester,
    ) async {
      await pumpDashboard(tester, manager: false);
      expect(find.text(l.dashMine), findsOneWidget);
      expect(find.text(l.dashWhoOwes), findsNothing);
      final mine = inFigure('-৳৮৩৪.৬৩');
      expect(mine, findsOneWidget);
      expect(tester.widget<Text>(mine).style?.color, AppPalette.light.due);
      expect(inFigure('১০'), findsOneWidget);
      expect(inFigure('৳৬৮৭.৮০'), findsOneWidget);
      expect(find.text(l.dashMyFoodProof('১০', '৳৮৩.৪১')), findsOneWidget);
      expect(inFigure('৳২৫০'), findsOneWidget);
      expect(inFigure('৳১,৫০০'), findsOneWidget);

      // Recent bazar: the last five only.
      expect(find.text(l.dashRecentBazar), findsOneWidget);
      for (var i = 1; i <= 5; i++) {
        expect(find.text(Fmt.money(100 + i, banglaDigits: true)), findsOne);
      }
      expect(find.text('৳১০৬'), findsNothing);

      await tester.tap(find.text(l.dashExplain));
      await tester.pumpAndSettle();
      expect(find.text(l.balanceExplainTitle('Karim')), findsOneWidget);
    });
  });

  group('charts', () {
    testWidgets('render with data and an accessible summary', (tester) async {
      await pumpDashboard(tester);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('ওয়াইফাই'), findsOneWidget);
      expect(find.text(l.bazarTitle), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp('^${l.dashDailyTitle}: ')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^${l.dashMonthlyTitle}: ')),
        findsOneWidget,
      );
      expect(find.text(l.dashChartEmpty), findsNothing);
    });

    testWidgets('empty data says so instead of drawing', (tester) async {
      await pumpDashboard(tester, emptyCharts: true);
      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(LineChart), findsNothing);
      expect(find.text(l.dashChartEmpty), findsNWidgets(3));
    });

    testWidgets('a failing chart fails alone, with retry', (tester) async {
      await pumpDashboard(tester, failDaily: true);
      expect(find.text(l.retry), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(inFigure('৳৮৩.৪১'), findsOneWidget);
    });
  });

  group('today empty states', () {
    late MockMealRepository repo;

    Future<void> pumpToday(WidgetTester tester, List<Member> members) async {
      repo = MockMealRepository();
      when(() => repo.mealTypes(any())).thenAnswer(
        (_) async => [
          const MealType(
            id: 'lunch',
            messId: 'mess1',
            name: 'দুপুর',
            sortOrder: 1,
            weight: 1,
            enabled: true,
          ),
        ],
      );
      when(
        () => repo.entriesForDay(any(), any()),
      ).thenAnswer((_) async => const []);
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const TodayScreen())],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealRepositoryProvider.overrideWithValue(repo),
            ...overrides(members: members),
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

    testWidgets('only a truly empty mess says "no members"', (tester) async {
      await pumpToday(tester, [
        member('new', 'Nobin', status: MemberStatus.pending),
      ]);
      expect(find.text(l.todayNoMembers), findsOneWidget);
      expect(find.text(l.dashNobodyThatDay), findsNothing);
      expect(find.byType(MonthDashboard), findsNothing);
    });
  });
}
