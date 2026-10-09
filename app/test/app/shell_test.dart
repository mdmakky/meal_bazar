import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/shell.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';

final l = lookupAppLocalizations(const Locale('bn'));

void main() {
  testWidgets('5 tabs: হোম · মিল · বাজার · হিসাব · আরও', (tester) async {
    final router = GoRouter(
      initialLocation: '/today',
      routes: [
        StatefulShellRoute(
          builder: (_, _, shell) => AppShell(shell: shell),
          navigatorContainerBuilder: AppShell.branchContainer,
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

    final bar = tester.widget<AppNavBar>(find.byType(AppNavBar));
    expect(bar.items.map((d) => d.label), [
      l.navHome,
      l.navMeals,
      l.navBazar,
      l.navMoney,
      l.navMore,
    ]);
    expect(find.text('page /today'), findsOneWidget);
    // Every destination is a ≥ 48 dp target.
    for (final label in bar.items.map((d) => d.label)) {
      final size = tester.getSize(
        find.ancestor(of: find.text(label), matching: find.byType(InkResponse)),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    double dotX() => tester.getCenter(find.byKey(const Key('nav-dot'))).dx;
    double labelX(String s) => tester.getCenter(find.text(s)).dx;
    expect(dotX(), moreOrLessEquals(labelX(l.navHome), epsilon: 0.5));

    await tester.tap(find.text(l.navBazar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Mid fade-through: the old tab is still on stage, fading out, and the
    // turmeric dot is on its way.
    expect(find.text('page /today'), findsOneWidget);
    expect(dotX(), greaterThan(labelX(l.navHome)));
    expect(dotX(), lessThan(labelX(l.navBazar)));
    await tester.pumpAndSettle();
    expect(find.text('page /bazar'), findsOneWidget);
    expect(find.text('page /today'), findsNothing); // offstage, state kept
    expect(dotX(), moreOrLessEquals(labelX(l.navBazar), epsilon: 0.5));
    final selected = tester.getSemantics(find.text(l.navBazar));
    expect(selected.flagsCollection.isSelected, isTrue);

    await tester.tap(find.text(l.navMeals));
    await tester.pumpAndSettle();
    expect(find.text('page /meals'), findsOneWidget);
  });
}
