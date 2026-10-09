import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/admin/application/admin_providers.dart';
import 'package:meal_bazar/admin/data/admin_repository.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void registerAdminFallbacks() {
  registerFallbackValue(<String, dynamic>{});
  registerFallbackValue(Uint8List(0));
}

/// A desktop-sized English panel around [child], backed by [repo].
Future<void> pumpAdmin(
  WidgetTester tester,
  Widget child, {
  required AdminRepository repo,
  List<Override> overrides = const [],
  bool scroll = true,
}) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        adminRepositoryProvider.overrideWithValue(repo),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: scroll ? SingleChildScrollView(child: child) : child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps Save and returns the value sent to `admin_set_config(key, …)`.
Future<Object?> saveAndCapture(
  WidgetTester tester,
  MockAdminRepository repo,
  String key,
) async {
  final save = find.text('Save').last;
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
  return verify(() => repo.setConfig(key, captureAny())).captured.single;
}

/// Scrolls [f] into view (tables scroll sideways), then taps it.
Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextFormField, label);
