import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/shell.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';

final l = lookupAppLocalizations(const Locale('bn'));

void main() {
  testWidgets('5 tabs: হোম · মিল · বাজার · হিসাব · আরও', (tester) async {
    final router = GoRouter(
      initialLocation: '/today',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => AppShell(shell: shell),
          branches: [
            for (final path in [
              '/today',
              '/meals',
              '/bazar',
              '/money',
              '/more',
            ])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (_, _) => Center(child: Text('page $path')),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    final labels = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((d) => d.label);
    expect(labels, [l.navHome, l.navMeals, l.navBazar, l.navMoney, l.navMore]);
    expect(find.text('page /today'), findsOneWidget);

    await tester.tap(find.text(l.navBazar));
    await tester.pumpAndSettle();
    expect(find.text('page /bazar'), findsOneWidget);

    await tester.tap(find.text(l.navMeals));
    await tester.pumpAndSettle();
    expect(find.text('page /meals'), findsOneWidget);
  });
}
