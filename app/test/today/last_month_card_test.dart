import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/dates.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/today/presentation/last_month_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform/fixed_config.dart';

final l = lookupAppLocalizations(const Locale('bn'));

/// The period that ended [daysAgo] days ago.
LastMonth last({
  required bool closed,
  int daysAgo = 2,
  double balance = 0,
  bool provisional = false,
  DateTime? reopenedAt,
}) {
  final end = today().subtract(Duration(days: daysAgo));
  return LastMonth(
    start: DateTime(end.year, end.month - 1, end.day),
    end: end,
    closed: closed,
    provisional: provisional,
    reopenedAt: reopenedAt,
    meals: closed || provisional ? 19.5 : null,
    foodCost: closed || provisional ? 1200 : null,
    extraCost: closed || provisional ? 250 : null,
    credit: closed || provisional ? 1450 + balance : null,
    openingBalance: closed || provisional ? 0 : null,
    closingBalance: closed || provisional ? balance : null,
  );
}

Future<void> pump(
  WidgetTester tester,
  LastMonth? month, {
  bool manager = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformConfig({}),
        amIManagerProvider.overrideWithValue(manager),
        lastMonthProvider.overrideWith((ref, id) async => month),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: LastMonthCard(messId: 'mess1')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('closed, in credit: final account, carried, dismissible', (
    tester,
  ) async {
    await pump(tester, last(closed: true, balance: 120));
    expect(find.text(l.lastMonthFinalTitle), findsOneWidget);
    expect(find.text(l.lastMonthAdvance), findsOneWidget);
    expect(find.text('৳১২০'), findsOneWidget);
    expect(find.text(l.lastMonthCarried), findsOneWidget);
    expect(find.text('১৯½'), findsOneWidget);
    expect(find.text('৳১,৪৫০'), findsOneWidget); // food + extra
    expect(find.text(l.lastMonthPay), findsNothing);

    await tester.tap(find.byTooltip(l.lastMonthHide));
    await tester.pumpAndSettle();
    expect(find.text(l.lastMonthFinalTitle), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('flags:mess1'), hasLength(1));
  });

  testWidgets('closed, due: বাকি and a pay button', (tester) async {
    await pump(tester, last(closed: true, balance: -300));
    expect(find.text(l.lastMonthDue), findsOneWidget);
    expect(find.text('৳৩০০'), findsOneWidget);
    expect(find.widgetWithText(AppButton, l.lastMonthPay), findsOneWidget);
  });

  testWidgets('closed long ago: nothing', (tester) async {
    await pump(tester, last(closed: true, daysAgo: 12, balance: 50));
    expect(find.text(l.lastMonthFinalTitle), findsNothing);
  });

  testWidgets('open without figures: a quiet "not final yet"', (tester) async {
    await pump(tester, last(closed: false));
    expect(find.text(l.lastMonthNotFinal), findsOneWidget);
  });

  testWidgets('provisional: figures labelled, no close call, no hide', (
    tester,
  ) async {
    await pump(
      tester,
      last(closed: false, provisional: true, balance: -300),
      manager: true,
    );
    expect(find.text(l.monthEndProvisionalTitle), findsOneWidget);
    expect(find.text(l.monthEndProvisionalBalance), findsOneWidget);
    expect(find.text(l.monthEndProvisionalNote), findsOneWidget);
    expect(find.text('৳৩০০'), findsOneWidget);
    expect(find.text(l.closeMonthCtaTitle), findsNothing);
    expect(find.widgetWithText(AppButton, l.monthClose), findsNothing);
    expect(find.byTooltip(l.lastMonthHide), findsNothing);
    expect(find.text(l.lastMonthCarried), findsNothing);
  });

  testWidgets('provisional while correcting says so', (tester) async {
    await pump(
      tester,
      last(
        closed: false,
        provisional: true,
        balance: 50,
        reopenedAt: DateTime(2026, 10, 3),
      ),
    );
    expect(find.text(l.monthEndCorrectionNote), findsOneWidget);
  });

  test('LastMonth parses provisional and reopened_at', () {
    final m = LastMonth.fromJson({
      'start_date': '2026-09-01',
      'end_date': '2026-10-01',
      'status': 'open',
      'meals': '12.5',
      'closing_balance': -40,
      'provisional': true,
      'reopened_at': '2026-10-02T04:00:00Z',
    });
    expect((m.closed, m.provisional), (false, true));
    expect(m.reopenedAt, isNotNull);
    expect(m.meals, 12.5);
    final old = LastMonth.fromJson({
      'start_date': '2026-09-01',
      'end_date': '2026-10-01',
      'status': 'closed',
    });
    expect((old.provisional, old.reopenedAt), (false, null));
  });

  testWidgets('no previous month: nothing', (tester) async {
    await pump(tester, null, manager: true);
    expect(find.byType(AppCard), findsNothing);
  });
}
