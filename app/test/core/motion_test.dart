import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';

Future<void> pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  bool reduceMotion = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      locale: const Locale('bn'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Records HapticFeedback calls.
List<String> recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add('${call.arguments}');
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

double dy(WidgetTester tester, String s) => tester.getCenter(find.text(s)).dy;

void main() {
  group('RollingNumber', () {
    testWidgets('rolls up per digit, settles to the Bangla money text', (
      tester,
    ) async {
      await pump(tester, const RollingNumber.money(1234, banglaDigits: true));
      expect(find.text('৳১,২৩৪'), findsOneWidget);

      await pump(tester, const RollingNumber.money(1235, banglaDigits: true));
      await tester.pump(const Duration(milliseconds: 120));
      // Mid-roll it is a row of character cells, not the final string.
      expect(find.text('৳১,২৩৫'), findsNothing);
      // Increasing: the new last digit (৫) rises from below the old (৪).
      expect(dy(tester, '৫'), greaterThan(dy(tester, '৪')));

      await tester.pumpAndSettle();
      expect(find.text('৳১,২৩৫'), findsOneWidget);
      expect(find.text('৪'), findsNothing);
      expect(find.bySemanticsLabel('৳১,২৩৫'), findsOneWidget);
    });

    testWidgets('direction: down when decreasing', (tester) async {
      await pump(tester, const RollingNumber(6));
      await pump(tester, const RollingNumber(5));
      await tester.pump(const Duration(milliseconds: 100));
      // The new 5 drops in from above the leaving 6.
      expect(dy(tester, '5'), lessThan(dy(tester, '6')));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsNothing);
    });

    testWidgets('negative and decimal values, English and Bangla', (
      tester,
    ) async {
      await pump(tester, const RollingNumber(-0.5));
      expect(find.text('-0.5'), findsOneWidget);
      await pump(tester, const RollingNumber(2.5));
      await tester.pumpAndSettle();
      expect(find.text('2.5'), findsOneWidget);

      await pump(tester, const RollingNumber(20.5, banglaDigits: true));
      await tester.pumpAndSettle();
      expect(find.text('২০.৫'), findsOneWidget);
      await pump(tester, const RollingNumber(0.5, banglaDigits: true));
      await tester.pumpAndSettle();
      expect(find.text('০.৫'), findsOneWidget);

      // Whole numbers drop the fraction; -0 is 0.
      await pump(tester, const RollingNumber(3.0));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
      await pump(tester, const RollingNumber(-0.001));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('signed money colours due → advance', (tester) async {
      Color? color(String s) => tester.widget<Text>(find.text(s)).style?.color;
      await pump(tester, const RollingNumber.money(-50, signed: true));
      expect(color('-৳50'), AppPalette.light.due);
      await pump(tester, const RollingNumber.money(70, signed: true));
      await tester.pumpAndSettle();
      expect(color('৳70'), AppPalette.light.advance);
    });

    testWidgets('Bangla digits keep 0 tracking under a tight style', (
      tester,
    ) async {
      final display = AppTheme.light().textTheme.displayLarge!;
      expect(display.letterSpacing, -0.5);
      await pump(tester, RollingNumber(12, banglaDigits: true, style: display));
      expect(tester.widget<Text>(find.text('১২')).style?.letterSpacing, 0);
    });

    testWidgets('Remove animations: instant swap', (tester) async {
      await pump(tester, const RollingNumber(10), reduceMotion: true);
      await pump(tester, const RollingNumber(99), reduceMotion: true);
      expect(find.text('99'), findsOneWidget);
      expect(find.byType(ClipRect), findsNothing); // no rolling cells
    });
  });

  testWidgets('PressableScale shrinks on press, keeps the tap, clicks', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    var taps = 0;
    await pump(
      tester,
      PressableScale(
        haptic: true,
        child: TextButton(onPressed: () => taps++, child: const Text('চাপুন')),
      ),
    );
    double scale() =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    final g = await tester.startGesture(tester.getCenter(find.text('চাপুন')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(scale(), 0.96);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    await g.up();
    await tester.pumpAndSettle();
    expect(scale(), 1);
    expect(taps, 1);
  });

  testWidgets('PressableScale: no scale with Remove animations', (
    tester,
  ) async {
    await pump(
      tester,
      PressableScale(
        child: TextButton(onPressed: () {}, child: const Text('চাপুন')),
      ),
      reduceMotion: true,
    );
    final g = await tester.startGesture(tester.getCenter(find.text('চাপুন')));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await g.up();
  });

  testWidgets('PopOnChange pops then returns to 1', (tester) async {
    double scale() => tester
        .widget<ScaleTransition>(
          find.ancestor(
            of: find.text('1'),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;
    await pump(tester, const PopOnChange(value: 1, child: Text('1')));
    expect(scale(), 1);
    await pump(tester, const PopOnChange(value: 2, child: Text('1')));
    await tester.pump(const Duration(milliseconds: 60));
    expect(scale(), greaterThan(1.1));
    await tester.pumpAndSettle();
    expect(scale(), 1);
  });

  group('StampMark', () {
    double scale(WidgetTester tester) => tester
        .widget<ScaleTransition>(
          find.descendant(
            of: find.byType(StampMark),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;

    testWidgets('lands from 1.4, rotated −8°, with a medium thump', (
      tester,
    ) async {
      final haptics = recordHaptics(tester);
      await pump(tester, const StampMark('পরিশোধিত'));
      await tester.pump(); // post-frame start
      await tester.pump(const Duration(milliseconds: 10));
      expect(scale(tester), greaterThan(1.3));
      final rotate = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(StampMark),
              matching: find.byType(Transform),
            )
            .last,
      );
      expect(rotate.transform.getRotation().entry(1, 0), closeTo(-0.139, 1e-3));
      await tester.pumpAndSettle();
      expect(scale(tester), 1);
      expect(haptics, ['HapticFeedbackType.mediumImpact']);
      expect(find.bySemanticsLabel('পরিশোধিত'), findsOneWidget);
    });

    testWidgets('accent colour; still when animate is false', (tester) async {
      final haptics = recordHaptics(tester);
      await pump(tester, const StampMark('বন্ধ', accent: true, animate: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(tester), 1);
      expect(haptics, isEmpty);
      expect(
        tester.widget<Text>(find.text('বন্ধ')).style?.color,
        AppPalette.light.accent,
      );
    });
  });

  testWidgets('StaggeredList: first 8 rows rise in order, once', (
    tester,
  ) async {
    late StateSetter setOuter;
    var extra = false;
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          setOuter = setState;
          return StaggeredList(
            child: Column(
              children: [
                ...StaggeredList.wrap([
                  for (var i = 0; i < 10; i++) Text('row $i'),
                ]),
                if (extra) const Stagger(index: 0, child: Text('late')),
              ],
            ),
          );
        },
      ),
    );
    FadeTransition? fadeOf(String s) => tester
        .widgetList<FadeTransition>(
          find.ancestor(
            of: find.text(s),
            matching: find.descendant(
              of: find.byType(Stagger),
              matching: find.byType(FadeTransition),
            ),
          ),
        )
        .firstOrNull;

    await tester.pump(const Duration(milliseconds: 100));
    expect(fadeOf('row 0')!.opacity.value, greaterThan(0));
    expect(fadeOf('row 7')!.opacity.value, 0); // still waiting its 210 ms
    expect(fadeOf('row 8'), isNull); // beyond the cap: just there
    await tester.pumpAndSettle();
    expect(fadeOf('row 7')!.opacity.value, 1);

    await tester.pump(const Duration(seconds: 1));
    setOuter(() => extra = true);
    await tester.pump();
    expect(fadeOf('late'), isNull); // mounted after the entrance window
  });

  group('AppCard variants', () {
    testWidgets('plain is the hairline Card; raised has layered shadows', (
      tester,
    ) async {
      await pump(tester, const AppCard(child: Text('plain')));
      expect(
        find.ancestor(of: find.text('plain'), matching: find.byType(Card)),
        findsOneWidget,
      );

      await pump(tester, const AppCard.raised(child: Text('raised')));
      final box = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('raised'),
              matching: find.byType(DecoratedBox),
            )
            .last,
      );
      final shadows = (box.decoration as BoxDecoration).boxShadow!;
      expect(shadows, AppElevation.raised(AppPalette.light));
      expect(shadows, hasLength(2));
      expect(
        tester
            .widget<Material>(
              find
                  .ancestor(
                    of: find.text('raised'),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color,
        AppPalette.light.surfaceRaised,
      );
    });

    for (final dark in [false, true]) {
      testWidgets('ink statement card (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        final palette = dark ? AppPalette.dark : AppPalette.light;
        await pump(
          tester,
          AppCard.ink(
            child: Builder(
              builder: (context) =>
                  Text('৳৬৮', style: Theme.of(context).textTheme.displayLarge),
            ),
          ),
          theme: dark ? AppTheme.dark() : AppTheme.light(),
        );
        final material = tester.widget<Material>(
          find
              .ancestor(of: find.text('৳৬৮'), matching: find.byType(Material))
              .first,
        );
        expect(material.color, palette.surfaceInk);
        final side = (material.shape! as RoundedRectangleBorder).side;
        expect(
          side,
          dark ? BorderSide(color: palette.surfaceInkBorder) : BorderSide.none,
        );
        expect(
          (material.shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(AppRadius.xl),
        );
        // Text on the card reads the statement palette, never ink-on-ink.
        expect(
          tester.widget<Text>(find.text('৳৬৮')).style?.color,
          palette.statement.ink,
        );
        expect(palette.statement.ink, isNot(palette.surfaceInk));
      });
    }
  });

  group('Theme and transitions', () {
    test('pushed routes use the 280 ms shared axis on Android', () {
      final builder = AppTheme.light()
          .pageTransitionsTheme
          .builders[TargetPlatform.android];
      expect(builder, isA<SharedAxisPageTransitionsBuilder>());
      expect(builder!.transitionDuration, const Duration(milliseconds: 280));
    });

    testWidgets('a push slides in from the right and settles', (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          theme: AppTheme.light(),
          home: const Scaffold(body: Text('first')),
        ),
      );
      key.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('second')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('first'), findsOneWidget);
      final midX = tester.getTopLeft(find.text('second')).dx;
      expect(midX, greaterThan(0));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('second')).dx, 0);
      expect(find.text('first'), findsNothing);
    });

    test('chips: selected fills ink with an onInk check', () {
      final chip = AppTheme.light().chipTheme;
      expect(chip.color!.resolve({WidgetState.selected}), AppPalette.light.ink);
      expect(chip.color!.resolve({}), AppPalette.light.surfaceRaised);
      expect(chip.showCheckmark, isTrue);
      expect(chip.checkmarkColor, AppPalette.light.onInk);
    });

    test('sheets 24 dp top corners; snackbar is a floating pill', () {
      final t = AppTheme.light();
      expect(
        (t.bottomSheetTheme.shape! as RoundedRectangleBorder).borderRadius,
        const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      );
      expect(t.snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(t.snackBarTheme.shape, isA<StadiumBorder>());
      expect(t.scaffoldBackgroundColor, const Color(0xFFF7F6F3));
    });

    test('every text role sets tabular figures', () {
      final t = AppTheme.light().textTheme;
      for (final s in [
        t.displayLarge,
        t.displaySmall,
        t.titleLarge,
        t.titleMedium,
        t.bodyLarge,
        t.bodyMedium,
        t.labelSmall,
      ]) {
        expect(s!.fontFeatures, contains(const FontFeature.tabularFigures()));
      }
    });
  });

  testWidgets('AppType.overline tracks English, not Bangla', (tester) async {
    late TextStyle bn;
    await pump(
      tester,
      Builder(
        builder: (context) {
          bn = AppType.overline(context);
          return const SizedBox();
        },
      ),
    );
    expect(bn.letterSpacing, 0);
    expect(bn.fontWeight, FontWeight.w600);
    expect(bn.fontSize, 12);
  });

  testWidgets('skeleton pulse is calm and finite; sync dot only when active', (
    tester,
  ) async {
    await pump(tester, const LoadingView(rows: 2));
    await tester.pump(const Duration(milliseconds: 600));
    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(SkeletonPulse),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, inInclusiveRange(0.55, 1));
    await tester.pumpAndSettle(); // would time out if it pulsed forever

    double dot() => tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(AnimatedSyncDot),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;
    await pump(tester, const AnimatedSyncDot(color: Colors.amber));
    await tester.pump(const Duration(milliseconds: 450));
    expect(dot(), lessThan(1)); // breathing
    await pump(
      tester,
      const AnimatedSyncDot(color: Colors.amber, active: false),
    );
    await tester.pump(const Duration(milliseconds: 450));
    expect(dot(), 1); // still
  });

  testWidgets('AppSnack shows an icon and the message', (tester) async {
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => AppSnack.show(context, 'সেভ হয়েছে'),
          child: const Text('go'),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('সেভ হয়েছে'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('AppButton cross-fades to its spinner and scales on press', (
    tester,
  ) async {
    await pump(tester, AppButton(label: 'সেভ', onPressed: () {}));
    expect(find.byType(PressableScale), findsOneWidget);
    await pump(
      tester,
      AppButton(label: 'সেভ', onPressed: () {}, loading: true),
    );
    await tester.pump(const Duration(milliseconds: 40));
    final label = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('সেভ'),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(label.opacity, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
