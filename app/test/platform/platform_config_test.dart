import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/platform/platform_config.dart';
import 'package:meal_bazar/core/platform/platform_widgets.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/theme/tokens.dart';
import 'package:meal_bazar/core/version.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/data/auth_repository.dart';
import 'package:meal_bazar/features/money/domain/bazar_catalogue.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixed_config.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

final l = lookupAppLocalizations(const Locale('bn'));

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Widget app(Widget home, List<Object> overrides) => ProviderScope(
  overrides: overrides.cast(),
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('bn'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parsing', () {
    test('missing, garbage and partial keys fall back to the defaults', () {
      for (final c in [
        const PlatformConfig(),
        PlatformConfig.fromJson(null),
        PlatformConfig.fromJson('nope'),
        PlatformConfig.fromJson({'app': 7, 'features': 'x', 'branding': []}),
      ]) {
        expect(c.feature('ai'), isTrue);
        expect(c.feature('anything_new'), isTrue);
        expect(c.aiMealDraft, isTrue);
        expect(c.maintenance, isFalse);
        expect(c.minVersion, '1.0.0');
        expect(c.needsUpdate(), isFalse);
        expect(c.bannerActive, isFalse);
        expect(c.supportEmail, '');
        expect(c.appName('bn'), 'মিল বাজার');
        expect(c.tagline('en'), 'Your whole mess, from your phone');
        expect(c.logoUrl, isNull);
        expect(c.accentLight, AppPalette.light.accent);
        expect(c.accentDark, AppPalette.dark.accent);
        expect(c.catalogue, isNull);
        expect(c.methodLabel('cash', 'bn'), isNull);
        expect(c.methodEnabled('cash'), isTrue);
      }

      final partial = PlatformConfig.fromJson({
        'app': {'maintenance': true, 'min_version': 5},
        'features': {'duty': false, 'notices': 'no'},
        'ai': {'enabled': false},
        'branding': {'accent_light': '#12345', 'accent_dark': '#00FF00'},
      });
      expect(partial.maintenance, isTrue);
      expect(partial.minVersion, '1.0.0'); // wrong type → default
      expect(partial.feature('duty'), isFalse);
      expect(partial.feature('notices'), isTrue); // only false turns off
      expect(partial.aiMealDraft, isFalse); // ai.enabled is a kill switch
      expect(partial.aiBazarScan, isFalse);
      expect(partial.accentLight, AppPalette.light.accent); // invalid hex
      expect(partial.accentDark, const Color(0xFF00FF00));
    });

    test('banner, branding, catalogue and payment methods', () {
      final c = PlatformConfig.fromJson({
        'app': {
          'banner': {'active': true, 'text_bn': ' নোটিশ ', 'level': 'loud'},
          'support_whatsapp': '+8801',
        },
        'branding': {'app_name_en': '', 'logo_url': 'https://x/logo.png'},
        'catalogue': {
          'groups': [
            {
              'name': 'ফল',
              'items': [
                {'name': 'আম', 'unit': 'কেজি'},
                {'name': 'কলা'},
                {'unit': 'no name'},
              ],
            },
            {'name': 'empty', 'items': []},
            'junk',
          ],
        },
        'payment_methods': [
          {'key': 'bkash', 'label_bn': 'বিকাশ পার্সোনাল', 'enabled': true},
          {'key': 'bank', 'label_en': 'Bank', 'enabled': false},
        ],
      });
      expect(c.bannerActive, isTrue);
      expect(c.bannerText('bn'), 'নোটিশ');
      expect(c.bannerLevel, BannerLevel.info);
      expect(c.supportWhatsapp, '+8801');
      expect(c.appName('en'), 'Meal Bazar'); // blank → default
      expect(c.logoUrl, 'https://x/logo.png');
      expect(c.catalogue!.map((g) => g.name), ['ফল']);
      expect(c.catalogue!.single.items, [
        (name: 'আম', unit: 'কেজি'),
        (name: 'কলা', unit: ''),
      ]);
      expect(catalogueUnit('আম', c.catalogue), 'কেজি');
      expect(catalogueUnit('কলা', c.catalogue), isNull);
      expect(catalogueUnit('ডিম', c.catalogue), isNull);
      expect(c.methodLabel('bkash', 'bn'), 'বিকাশ পার্সোনাল');
      expect(c.methodLabel('bkash', 'en'), isNull);
      expect(c.methodEnabled('bank'), isFalse);
      expect(c.methodEnabled('nagad'), isTrue);
    });
  });

  group('version', () {
    test('compareVersions is numeric and ignores the build', () {
      expect(compareVersions('1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.9.2', '1.10.0'), lessThan(0));
      expect(compareVersions('2.0', '1.99.99'), greaterThan(0));
      expect(compareVersions('1.0.0+7', '1.0.0'), 0);
      expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(
        PlatformConfig.fromJson({
          'app': {'min_version': '1.0.1'},
        }).needsUpdate('1.0.0'),
        isTrue,
      );
    });

    test('appVersion matches pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final v = RegExp(
        r'^version:\s*([^+\s]+)',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1);
      expect(appVersion, v);
    });
  });

  group('provider', () {
    test('cache first, then the server; refresh throttled to 5 min', () async {
      SharedPreferences.setMockInitialValues({
        PlatformConfigNotifier.cacheKey: jsonEncode({
          'app': {'maintenance': true},
        }),
      });
      var calls = 0;
      final server = Completer<Object?>();
      final container = ProviderContainer(
        overrides: [
          platformConfigFetchProvider.overrideWithValue(() {
            calls++;
            return calls == 1
                ? server.future
                : Future.value({
                    'features': {'ai': false},
                  });
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(platformConfigProvider, (_, _) {});

      // First frame: defaults, never blocked.
      expect(container.read(platformConfigProvider).maintenance, isFalse);
      await settle();
      expect(container.read(platformConfigProvider).maintenance, isTrue);

      server.complete({
        'app': {'maintenance': false, 'min_version': '9.0.0'},
      });
      await settle();
      final c = container.read(platformConfigProvider);
      expect(c.maintenance, isFalse);
      expect(c.needsUpdate(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(PlatformConfigNotifier.cacheKey),
        contains('9.0.0'),
      );

      final n = container.read(platformConfigProvider.notifier);
      await n.refresh();
      expect(calls, 1);
      await n.refresh(force: true);
      expect(calls, 2);
      expect(container.read(platformConfigProvider).feature('ai'), isFalse);
    });

    test('a failing RPC keeps the defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          platformConfigFetchProvider.overrideWithValue(
            () => Future.error(Exception('function does not exist')),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(platformConfigProvider, (_, _) {});
      await settle();
      expect(container.read(platformConfigProvider).feature('duty'), isTrue);
    });
  });

  group('gate', () {
    late MockAuthRepository auth;
    setUp(() {
      auth = MockAuthRepository();
      when(() => auth.signOut()).thenAnswer((_) async {});
    });

    List<Object> overrides(Map<String, Object?> json) => [
      platformConfig(json),
      authStateProvider.overrideWith((ref) => Stream.value('u1')),
      authRepositoryProvider.overrideWithValue(auth),
    ];

    testWidgets('maintenance covers the app; sign-out still works', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const PlatformGate(child: Text('home')),
          overrides({
            'app': {
              'maintenance': true,
              'maintenance_message_bn': 'রাত ১২টা পর্যন্ত বন্ধ',
            },
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l.platformMaintenanceTitle), findsOneWidget);
      expect(find.text('রাত ১২টা পর্যন্ত বন্ধ'), findsOneWidget);
      await tester.tap(find.text(l.platformSignOut));
      verify(() => auth.signOut()).called(1);
    });

    testWidgets('no maintenance, current version: just the app', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const PlatformGate(child: Text('home')), overrides({})),
      );
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(find.text(l.platformMaintenanceTitle), findsNothing);
      expect(find.text(l.platformUpdateTitle), findsNothing);
    });

    testWidgets('below min_version: a dismissible update prompt', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const PlatformGate(child: Text('home')),
          overrides({
            'app': {'min_version': '99.0.0'},
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l.platformUpdateTitle), findsOneWidget);
      expect(find.text(l.platformUpdateBody), findsOneWidget);
      await tester.tap(find.text(l.platformUpdateLater));
      await tester.pumpAndSettle();
      expect(find.text(l.platformUpdateTitle), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('banner and branding', () {
    testWidgets('banner shows by level and stays dismissed for its text', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final cfg = platformConfig({
        'app': {
          'banner': {
            'active': true,
            'text_bn': 'আজ রাতে সার্ভার আপডেট',
            'level': 'critical',
          },
        },
      });
      await tester.pumpWidget(
        app(const Scaffold(body: PlatformBanner()), [cfg]),
      );
      await tester.pumpAndSettle();
      expect(find.text('আজ রাতে সার্ভার আপডেট'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.tap(find.byTooltip(l.platformBannerDismiss));
      await tester.pumpAndSettle();
      expect(find.text('আজ রাতে সার্ভার আপডেট'), findsNothing);

      // Same text after a restart: still dismissed.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        app(const Scaffold(body: PlatformBanner()), [cfg]),
      );
      await tester.pumpAndSettle();
      expect(find.text('আজ রাতে সার্ভার আপডেট'), findsNothing);
    });

    testWidgets('inactive banner is hidden', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        app(const Scaffold(body: PlatformBanner()), [
          platformConfig({
            'app': {
              'banner': {'active': false, 'text_bn': 'লুকানো'},
            },
          }),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('লুকানো'), findsNothing);
    });

    testWidgets('brand header: config name and tagline, bundled mark', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const Scaffold(body: BrandHeader()), [
          platformConfig({
            'branding': {'app_name_bn': 'আমাদের মেস', 'logo_url': null},
          }),
        ]),
      );
      expect(find.text('আমাদের মেস'), findsOneWidget);
      expect(find.text('মেসের পুরো হিসাব, ফোন থেকেই'), findsOneWidget);
      expect(find.byKey(const Key('brand-fallback')), findsOneWidget);
    });

    testWidgets('a broken logo falls back to the bundled mark', (tester) async {
      await tester.pumpWidget(
        app(const Scaffold(body: BrandMark()), [
          platformConfig({
            'branding': {'logo_url': 'https://example.invalid/logo.png'},
          }),
        ]),
      );
      // The test HTTP client answers 400, so the errorBuilder runs.
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('brand-fallback')), findsOneWidget);
    });
  });
}
