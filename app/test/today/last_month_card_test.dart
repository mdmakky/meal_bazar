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
LastMonth last({required bool closed, int daysAgo = 2, double balance = 0}) {
  final end = today().subtract(Duration(days: daysAgo));
  return LastMonth(
    start: DateTime(end.year, end.month - 1, end.day),
    end: end,
    closed: closed,
    meals: closed ? 19.5 : null,
    foodCost: closed ? 1200 : null,
    extraCost: closed ? 250 : null,
    credit: closed ? 1450 + balance : null,
    openingBalance: closed ? 0 : null,
    closingBalance: closed ? balance : null,
  );
}

Future<void> pump(
  WidgetTester tester,
  LastMonth? month, {
  bool manager = false,
  PendingItems pending = (deposits: 0, bazarRequests: 0),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformConfig({}),
        amIManagerProvider.overrideWithValue(manager),
        lastMonthProvider.overrideWith((ref, id) async => month),
        pendingItemsProvider.overrideWith((ref, k) async => pending),
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

  testWidgets('open, member: a quiet "not final yet"', (tester) async {
    await pump(tester, last(closed: false));
    expect(find.text(l.lastMonthNotFinal), findsOneWidget);
    expect(find.text(l.closeMonthCtaTitle), findsNothing);
  });

  testWidgets('open, manager with pending items: close is blocked', (
    tester,
  ) async {
    await pump(
      tester,
      last(closed: false),
      manager: true,
      pending: (deposits: 3, bazarRequests: 0),
    );
    expect(find.text(l.closeMonthCtaTitle), findsOneWidget);
    expect(find.text(l.closeMonthPendingDeposits('৩')), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, l.monthClose))
          .onPressed,
      isNull,
    );
  });

  testWidgets('open, manager, nothing pending: close is ready', (tester) async {
    await pump(tester, last(closed: false), manager: true);
    expect(find.text(l.closeMonthPendingTitle), findsNothing);
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, l.monthClose))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('no previous month: nothing', (tester) async {
    await pump(tester, null, manager: true);
    expect(find.byType(AppCard), findsNothing);
  });
}
