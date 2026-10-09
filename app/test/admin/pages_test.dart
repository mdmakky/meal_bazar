import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/admin/application/admin_providers.dart';
import 'package:meal_bazar/admin/domain/admin_models.dart';
import 'package:meal_bazar/admin/presentation/admin_app.dart';
import 'package:meal_bazar/admin/presentation/branding_page.dart';
import 'package:meal_bazar/admin/presentation/credentials_page.dart';
import 'package:meal_bazar/admin/presentation/messes_users_pages.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/data/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

import 'harness.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAdminRepository repo;

  setUpAll(registerAdminFallbacks);
  setUp(() => repo = MockAdminRepository());

  group('access gate', () {
    testWidgets('signed-in non-admin sees access denied and can sign out', (
      t,
    ) async {
      final auth = MockAuthRepository();
      when(auth.signOut).thenAnswer((_) async {});
      when(repo.isPlatformAdmin).thenAnswer((_) async => false);
      await pumpAdmin(
        t,
        const AdminGate(),
        repo: repo,
        scroll: false,
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          adminSessionProvider.overrideWith((ref) => Stream.value('u1')),
        ],
      );
      expect(find.text('Access denied'), findsOneWidget);
      await t.tap(find.text('Sign out'));
      verify(auth.signOut).called(1);
    });

    testWidgets('signed out shows the sign-in form', (t) async {
      await pumpAdmin(
        t,
        const AdminGate(),
        repo: repo,
        scroll: false,
        overrides: [
          adminSessionProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      expect(find.text('Sign in'), findsOneWidget);
      verifyNever(repo.isPlatformAdmin);
    });
  });

  group('messes page', () {
    setUp(() {
      when(() => repo.listMesses(any(), any(), any())).thenAnswer(
        (_) async => [
          const MessRow(id: 'm1', name: 'Green House', memberCount: 6),
        ],
      );
      when(
        () => repo.setMessSuspended(any(), any(), any()),
      ).thenAnswer((_) async {});
      when(repo.stats).thenAnswer((_) async => AdminStats.fromJson(const {}));
    });

    testWidgets('suspend asks for a reason, then calls the RPC', (t) async {
      await pumpAdmin(t, const MessesPage(), repo: repo, scroll: false);
      expect(find.text('Green House'), findsOneWidget);
      verify(() => repo.listMesses('', adminPageSize, 0)).called(1);

      await t.tap(find.text('Suspend'));
      await t.pumpAndSettle();
      expect(find.text('Suspend the mess "Green House"?'), findsOneWidget);

      // A reason is required.
      await t.tap(find.text('Suspend').last);
      await t.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
      verifyNever(() => repo.setMessSuspended(any(), any(), any()));

      await t.enterText(find.byType(TextFormField), 'Spam messes');
      await t.tap(find.text('Suspend').last);
      await t.pumpAndSettle();
      verify(() => repo.setMessSuspended('m1', true, 'Spam messes')).called(1);
      // The table reloads after the write.
      verify(() => repo.listMesses('', adminPageSize, 0)).called(1);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('search resets to page 1 with the query', (t) async {
      await pumpAdmin(t, const MessesPage(), repo: repo, scroll: false);
      await t.enterText(find.byType(TextField), 'green');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      verify(() => repo.listMesses('green', adminPageSize, 0)).called(1);
    });
  });

  group('credentials', () {
    setUp(() {
      when(repo.listSecrets).thenAnswer(
        (_) async => [
          SecretRow(
            name: 'GEMINI_API_KEY',
            last4: 'abcd',
            updatedAt: DateTime.utc(2026, 10, 2),
          ),
        ],
      );
      when(() => repo.setSecret(any(), any())).thenAnswer((_) async {});
    });

    testWidgets('lists every allowed name, masked, never values', (t) async {
      await pumpAdmin(t, const CredentialsPage(), repo: repo, scroll: false);
      for (final n in secretNames) {
        expect(find.text(n), findsOneWidget);
      }
      expect(find.textContaining('••••abcd'), findsOneWidget);
      expect(find.text('Replace'), findsOneWidget);
      expect(find.text('Set'), findsNWidgets(5));
    });

    testWidgets('set sends the typed value; delete asks first', (t) async {
      await pumpAdmin(t, const CredentialsPage(), repo: repo, scroll: false);
      await t.tap(find.text('Set').first); // OPENROUTER_API_KEY
      await t.pumpAndSettle();
      final input = find.byType(TextFormField);
      expect(
        t.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
      await t.enterText(input, ' sk-or-123 ');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      verify(() => repo.setSecret('OPENROUTER_API_KEY', 'sk-or-123')).called(1);

      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      expect(find.text('Delete GEMINI_API_KEY?'), findsOneWidget);
      await t.tap(find.text('Delete').last);
      await t.pumpAndSettle();
      verify(() => repo.setSecret('GEMINI_API_KEY', null)).called(1);
    });
  });

  group('branding', () {
    setUp(() {
      when(() => repo.setConfig(any(), any())).thenAnswer((_) async {});
      when(
        () => repo.uploadLogo(any(), any()),
      ).thenAnswer((_) async => 'https://cdn.example/logo-1.png');
    });

    testWidgets('upload logo, edit name and accent, contrast shown', (t) async {
      await pumpAdmin(
        t,
        const BrandingEditor(saved: null),
        repo: repo,
        overrides: [
          logoPickerProvider.overrideWithValue(
            () async => (bytes: [1, 2, 3], ext: 'png'),
          ),
        ],
      );
      expect(find.textContaining('new release'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^Contrast \d')), findsNWidgets(2));

      await t.tap(find.text('Upload logo'));
      await t.pumpAndSettle();
      verify(() => repo.uploadLogo(any(), 'png')).called(1);
      expect(find.text('Remove logo'), findsOneWidget);

      await t.enterText(field('App name (English)'), 'Mess Pro');
      await t.enterText(field('Light theme'), 'C98A0B');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(find.text('Use a #RRGGBB colour'), findsWidgets);
      verifyNever(() => repo.setConfig(any(), any()));

      // Pale yellow on white: allowed, but flagged as low contrast.
      await t.enterText(field('Light theme'), '#FFF2A0');
      await t.pumpAndSettle();
      expect(find.textContaining('Low contrast'), findsOneWidget);
      final v = await saveAndCapture(t, repo, 'branding') as Map;
      expect(v, {
        'app_name_bn': 'মিল বাজার',
        'app_name_en': 'Mess Pro',
        'tagline_bn': 'মেসের পুরো হিসাব, ফোন থেকেই',
        'tagline_en': 'Your whole mess, from your phone',
        'logo_url': 'https://cdn.example/logo-1.png',
        'accent_light': '#FFF2A0',
        'accent_dark': '#E8B33A',
      });
    });

    testWidgets('remove logo saves null', (t) async {
      await pumpAdmin(
        t,
        const BrandingEditor(
          saved: {'logo_url': 'https://cdn.example/old.png'},
        ),
        repo: repo,
      );
      await t.tap(find.text('Remove logo'));
      await t.pumpAndSettle();
      final v = await saveAndCapture(t, repo, 'branding') as Map;
      expect(v['logo_url'], isNull);
    });
  });
}
