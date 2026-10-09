import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/widgets/launch_intro.dart';

void main() {
  Future<void> pump(WidgetTester tester, ValueNotifier<bool> ready) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('bn'),
        home: LaunchIntro(
          ready: ready,
          isReady: () => ready.value,
          child: const Text('home'),
        ),
      ),
    );
    // Let the logo layers decode (real asset I/O).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
  }

  testWidgets('covers the app until it is routed, then lifts away', (
    tester,
  ) async {
    final ready = ValueNotifier(false);
    await pump(tester, ready);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(AbsorbPointer), findsWidgets);
    expect(find.text('মিল বাজার'), findsOneWidget);

    ready.value = true;
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('মিল বাজার'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('never holds the app longer than maxWait', (tester) async {
    final ready = ValueNotifier(false);
    await pump(tester, ready);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('মিল বাজার'), findsNothing);
  });
}
