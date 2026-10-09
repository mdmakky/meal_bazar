import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';

Future<void> pumpCell(WidgetTester tester, MealCell cell) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('bn'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: cell)),
  ),
);

void main() {
  testWidgets('renders 1, ½ and 0 with Bangla digits', (tester) async {
    await pumpCell(
      tester,
      const MealCell(label: 'Rahim দুপুর', count: 1, banglaDigits: true),
    );
    expect(find.text('১'), findsOneWidget);
    expect(find.bySemanticsLabel('Rahim দুপুর: ১'), findsOneWidget);

    await pumpCell(tester, const MealCell(label: 'x', count: 0.5));
    await tester.pumpAndSettle();
    expect(find.text('½'), findsOneWidget);

    await pumpCell(tester, const MealCell(label: 'x', banglaDigits: true));
    await tester.pumpAndSettle();
    expect(find.text('০'), findsOneWidget);
  });

  testWidgets('Off says অফ (not a dash, not ০); guests show +n', (
    tester,
  ) async {
    await pumpCell(
      tester,
      const MealCell(
        label: 'Karim রাত',
        off: true,
        guests: 2,
        banglaDigits: true,
      ),
    );
    expect(find.text('অফ'), findsOneWidget);
    expect(find.text('—'), findsNothing);
    expect(find.text('+২'), findsOneWidget);
    expect(find.bySemanticsLabel('Karim রাত: অফ, +২ জন অতিথি'), findsOneWidget);
  });

  testWidgets('fires tap and long-press; 48 dp tall', (tester) async {
    var taps = 0, holds = 0;
    await pumpCell(
      tester,
      MealCell(
        label: 'x',
        count: 1,
        onTap: () => taps++,
        onLongPress: () => holds++,
      ),
    );
    await tester.tap(find.byType(MealCell));
    await tester.longPress(find.byType(MealCell));
    expect((taps, holds), (1, 1));
    final size = tester.getSize(find.byType(MealCell));
    expect(size.width, greaterThanOrEqualTo(AppSize.mealCellWidth));
    expect(size.height, greaterThanOrEqualTo(AppSize.touch));
  });
}
