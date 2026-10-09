import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/money/application/money_providers.dart';
import 'package:meal_bazar/features/money/data/money_repository.dart';
import 'package:meal_bazar/features/money/domain/money.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/month/presentation/month_end_review_screen.dart';
import 'package:meal_bazar/features/month/presentation/month_status_chip.dart';
import 'package:mocktail/mocktail.dart';

import '../platform/fixed_config.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

class _Mess extends CurrentMessId {
  @override
  String? build() => 'mess1';
}

final l = lookupAppLocalizations(const Locale('bn'));
final start = DateTime(2026, 9, 1);

MonthStatus status({
  String state = 'open',
  int deposits = 0,
  int requests = 0,
  int missing = 0,
  String auto = 'off',
  bool canClose = true,
  int closedMissing = 0,
  bool reconstructed = false,
}) => MonthStatus(
  start: start,
  end: DateTime(2026, 10, 1),
  status: state,
  closedAt: state == 'closed' ? DateTime(2026, 10, 2, 9, 5) : null,
  closedMissing: closedMissing,
  totals: const MonthTotals(
    foodTotal: 1410,
    totalMeals: 20.5,
    mealRate: 68.78,
    extraTotal: 500,
    creditTotal: 1500,
  ),
  pendingDeposits: deposits,
  pendingBazarRequests: requests,
  missingDays: missing,
  autoState: auto,
  totalsReconstructed: reconstructed,
  canClose: canClose,
);

const balances = [
  MemberBalance(
    memberId: 'k',
    displayName: 'Karim',
    meals: 8.5,
    foodCost: 584,
    extraCost: 250,
    credit: 0,
    openingBalance: 0,
    closingBalance: -834,
  ),
  MemberBalance(
    memberId: 'r',
    displayName: 'Rahim',
    meals: 12,
    foodCost: 825,
    extraCost: 250,
    credit: 1500,
    openingBalance: 0,
    closingBalance: 425,
  ),
];

late MockMoneyRepository repo;

Future<void> pump(
  WidgetTester tester,
  Widget home,
  MonthStatus? s, {
  bool manager = true,
}) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformConfig({}),
        moneyRepositoryProvider.overrideWithValue(repo),
        currentMessIdProvider.overrideWith(_Mess.new),
        amIManagerProvider.overrideWithValue(manager),
        monthStatusProvider.overrideWith((ref, id) async => s),
        periodSummaryProvider.overrideWith(
          (ref, k) async =>
              (MonthPeriod(start, DateTime(2026, 10, 1)), s!.totals, balances),
        ),
        monthMissingMealsProvider.overrideWith(
          (ref, k) async => [
            (day: DateTime(2026, 9, 3), memberId: 'k', name: 'Karim'),
            (day: DateTime(2026, 9, 3), memberId: 'r', name: 'Rahim'),
            (day: DateTime(2026, 9, 4), memberId: 'k', name: 'Karim'),
          ],
        ),
        monthsProvider.overrideWith(
          (ref, id) async => [
            MessMonth(
              id: 'sep',
              start: start,
              end: DateTime(2026, 10, 1),
              closed: s?.isClosed ?? false,
              reopenReason: 'ভুল বাজার',
            ),
          ],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));
  setUp(() {
    repo = MockMoneyRepository();
    when(
      () => repo.closeMonth(
        any(),
        any(),
        confirmMissing: any(named: 'confirmMissing'),
      ),
    ).thenAnswer((_) async => 'sep');
  });

  group('chip', () {
    Future<void> chip(WidgetTester t, MonthStatus? s, {bool manager = true}) =>
        pump(t, const Scaffold(body: MonthStatusChip()), s, manager: manager);

    testWidgets('pending close shows the month and an action', (t) async {
      await chip(t, status());
      expect(find.text(l.monthEndChipClose('সেপ্টেম্বর')), findsOneWidget);
    });
    testWidgets('pending items need attention', (t) async {
      await chip(t, status(deposits: 1));
      expect(find.text(l.monthEndChipAttention), findsOneWidget);
    });
    testWidgets('missing meals or a failed auto run need attention', (t) async {
      await chip(t, status(missing: 2));
      expect(find.text(l.monthEndChipAttention), findsOneWidget);
      await chip(t, status(auto: 'failed'));
      expect(find.text(l.monthEndChipAttention), findsOneWidget);
    });
    testWidgets('correcting', (t) async {
      await chip(t, status(state: 'correcting'));
      expect(find.text(l.monthEndChipCorrecting), findsOneWidget);
    });
    testWidgets('closed', (t) async {
      await chip(t, status(state: 'closed'));
      expect(find.text(l.monthEndChipClosed), findsOneWidget);
    });
    testWidgets('hidden for members and with no period', (t) async {
      await chip(t, status(), manager: false);
      expect(find.byKey(const Key('monthStatusChip')), findsNothing);
      await chip(t, null);
      expect(find.byKey(const Key('monthStatusChip')), findsNothing);
    });
  });

  group('review', () {
    const screen = MonthEndReviewScreen();

    testWidgets('nothing pending: ready, totals and balances shown', (t) async {
      await pump(t, screen, status());
      expect(find.byKey(const Key('review-ready')), findsOneWidget);
      expect(find.text(l.moneyFoodTotal), findsOneWidget);
      expect(find.byKey(const Key('balance-table')), findsOneWidget);
      expect(find.text('Karim'), findsOneWidget);
      expect(find.text(l.monthEndProvisional), findsOneWidget);
      expect(find.byKey(const Key('confirm-missing')), findsNothing);
      expect(
        t.widget<AppButton>(find.byKey(const Key('review-close'))).onPressed,
        isNotNull,
      );
    });

    testWidgets('pending items and a pending auto run block closing', (
      t,
    ) async {
      await pump(
        t,
        screen,
        status(deposits: 2, requests: 1, auto: 'pending', canClose: false),
      );
      expect(find.text(l.monthEndPendingDeposits('২')), findsOneWidget);
      expect(find.text(l.monthEndPendingBazar('১')), findsOneWidget);
      expect(find.text(l.monthEndAutoPending), findsOneWidget);
      expect(find.byKey(const Key('review-ready')), findsNothing);
      expect(
        t.widget<AppButton>(find.byKey(const Key('review-close'))).onPressed,
        isNull,
      );
      expect(find.text(l.monthEndBlockedPending), findsOneWidget);
    });

    testWidgets('reconstructed and provisional-opening notes', (t) async {
      await pump(t, screen, status(reconstructed: true));
      expect(find.text(l.monthEndReconstructed), findsOneWidget);
    });

    testWidgets('missing meals: grouped by date, checkbox gates close', (
      t,
    ) async {
      await pump(t, screen, status(missing: 3));
      expect(find.byKey(const Key('missing-2026-09-03')), findsOneWidget);
      expect(find.text('Karim, Rahim'), findsOneWidget);
      final close = find.byKey(const Key('review-close'));
      await t.ensureVisible(close);
      expect(t.widget<AppButton>(close).onPressed, isNull);
      expect(find.text(l.monthEndBlockedConfirm), findsOneWidget);

      await t.tap(find.byKey(const Key('confirm-missing')));
      await t.pumpAndSettle();
      expect(t.widget<AppButton>(close).onPressed, isNotNull);

      await t.tap(close);
      await t.pumpAndSettle();
      // The sheet shows the final figures and what closing does.
      expect(find.text(l.monthEndConfirmFinalFigures), findsOneWidget);
      expect(find.text(l.closeMonthLocked), findsOneWidget);
      verifyNever(
        () => repo.closeMonth(
          any(),
          any(),
          confirmMissing: any(named: 'confirmMissing'),
        ),
      );
      await t.tap(find.byKey(const Key('confirm-close')));
      await t.pumpAndSettle();
      verify(
        () => repo.closeMonth('mess1', start, confirmMissing: true),
      ).called(1);
    });

    testWidgets('no missing entries: closes without the flag', (t) async {
      await pump(t, screen, status());
      final close = find.byKey(const Key('review-close'));
      await t.ensureVisible(close);
      await t.tap(close);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('confirm-close')));
      await t.pumpAndSettle();
      verify(
        () => repo.closeMonth('mess1', start, confirmMissing: false),
      ).called(1);
    });

    testWidgets('correcting: banner with the reason', (t) async {
      await pump(t, screen, status(state: 'correcting'));
      expect(find.byKey(const Key('correction-banner')), findsOneWidget);
      expect(
        find.text(l.monthEndCorrectionReason('ভুল বাজার')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('review-close')), findsOneWidget);
    });

    testWidgets('closed: final report, confirmed gaps, reopen', (t) async {
      await pump(t, screen, status(state: 'closed', closedMissing: 4));
      expect(find.text(l.monthEndFinal), findsOneWidget);
      expect(find.text(l.monthEndClosedMissing('৪')), findsOneWidget);
      expect(find.byKey(const Key('review-reopen')), findsOneWidget);
      expect(find.byKey(const Key('review-close')), findsNothing);
      expect(find.byKey(const Key('review-ready')), findsNothing);
    });

    testWidgets('members never see it', (t) async {
      await pump(t, screen, status(), manager: false);
      expect(find.text(l.monthManagerOnly), findsOneWidget);
      expect(find.byKey(const Key('review-close')), findsNothing);
    });
  });
}
