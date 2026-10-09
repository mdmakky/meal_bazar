import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';

Future<void> pumpApp(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('bn'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('AppButton loading keeps width and blocks taps', (tester) async {
    var taps = 0;
    Widget button(bool loading) => AppButton(
      key: const Key('b'),
      label: 'মিল সেভ করুন',
      loading: loading,
      onPressed: () => taps++,
    );

    await pumpApp(tester, button(false));
    final width = tester.getSize(find.byKey(const Key('b'))).width;
    await tester.tap(find.byKey(const Key('b')));
    expect(taps, 1);

    await pumpApp(tester, button(true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('b'))).width, width);
    await tester.tap(find.byKey(const Key('b')), warnIfMissed: false);
    expect(taps, 1);
  });

  testWidgets('Money signed colors due/advance', (tester) async {
    Color? colorOf(String s) => tester.widget<Text>(find.text(s)).style?.color;

    await pumpApp(
      tester,
      const Column(
        children: [
          Money(-50, signed: true),
          Money(70, signed: true),
          Money(90),
        ],
      ),
    );
    expect(colorOf('-৳50'), AppPalette.light.due);
    expect(colorOf('৳70'), AppPalette.light.advance);
    expect(colorOf('৳90'), isNull);
  });

  testWidgets('Figure tap toggles proof', (tester) async {
    await pumpApp(
      tester,
      const Figure(
        value: '৳৬৮.৭৮',
        label: 'মিল রেট',
        proof: '৳১,৪১০ ÷ ২০.৫ মিল',
      ),
    );
    expect(find.text('৳১,৪১০ ÷ ২০.৫ মিল'), findsNothing);
    await tester.tap(find.text('৳৬৮.৭৮'));
    await tester.pumpAndSettle();
    expect(find.text('৳১,৪১০ ÷ ২০.৫ মিল'), findsOneWidget);
    await tester.tap(find.text('৳৬৮.৭৮'));
    await tester.pumpAndSettle();
    expect(find.text('৳১,৪১০ ÷ ২০.৫ মিল'), findsNothing);
  });

  testWidgets('SyncBadge states; synced says nothing', (tester) async {
    var retried = false;
    await pumpApp(tester, const SyncBadge(state: SyncState.synced));
    expect(find.byType(Text), findsNothing);
    expect(find.text('সেভ হয়েছে'), findsNothing);

    await pumpApp(tester, const SyncBadge(state: SyncState.offline));
    expect(find.text('অফলাইনে সেভ হয়েছে'), findsOneWidget);

    await pumpApp(tester, const SyncBadge(state: SyncState.syncing));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('সিঙ্ক হচ্ছে'), findsOneWidget);

    await pumpApp(
      tester,
      SyncBadge(state: SyncState.failed, onRetry: () => retried = true),
    );
    expect(find.text('সিঙ্ক হয়নি'), findsOneWidget);
    await tester.tap(find.text('আবার চেষ্টা করুন'));
    expect(retried, isTrue);
  });

  testWidgets('CountBadge: a Bangla digit sits whole inside a round badge', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: CountBadge(1, key: Key('b')),
      ),
    );
    final box = tester.getRect(find.byKey(const Key('b')));
    final digit = tester.getRect(find.text('১'));
    expect(box.width, greaterThanOrEqualTo(CountBadge.size));
    expect(box.height, greaterThanOrEqualTo(CountBadge.size));
    expect(
      box.contains(digit.topLeft) &&
          box.contains(digit.bottomRight - const Offset(0.1, 0.1)),
      isTrue,
    );
    expect((box.center - digit.center).distance, lessThan(1));
    expect(find.bySemanticsLabel('১টি অপঠিত'), findsOneWidget);

    await pumpApp(tester, const CountBadge(0));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('ErrorView retry calls back', (tester) async {
    var retried = 0;
    await pumpApp(tester, ErrorView(onRetry: () => retried++));
    expect(
      find.text('কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।'),
      findsOneWidget,
    );
    await tester.tap(find.text('আবার চেষ্টা করুন'));
    expect(retried, 1);
  });

  testWidgets('LoadingView, EmptyView, AppCard and dark theme build', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Column(
            children: [
              LoadingView(rows: 1),
              AppCard(child: Text('x')),
              Expanded(child: EmptyView(message: 'খালি')),
            ],
          ),
        ),
      ),
    );
    expect(find.text('খালি'), findsOneWidget);
  });
}
