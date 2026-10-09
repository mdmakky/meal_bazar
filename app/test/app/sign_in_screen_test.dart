import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations_bn.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/data/auth_repository.dart';
import 'package:meal_bazar/features/auth/presentation/sign_in_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../platform/fixed_config.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  final l = AppLocalizationsBn();
  late MockAuthRepository repo;

  Future<void> pump(
    WidgetTester tester, {
    bool google = true,
    Map<String, Object?> config = const {},
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        platformConfig(config),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SignInScreen(googleEnabled: google),
      ),
    ),
  );

  Future<void> fill(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.enterText(find.byKey(const Key('password')), password);
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
  }

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.signInWithEmail(any(), any())).thenAnswer((_) async {});
    when(
      () => repo.signUpWithEmail(any(), any()),
    ).thenAnswer((_) async => false);
    when(() => repo.signInWithGoogle()).thenAnswer((_) async => false);
  });

  testWidgets('invalid email and short password are blocked', (tester) async {
    await pump(tester);
    await fill(tester, 'not-an-email', 'short');
    expect(find.text(l.signInEmailInvalid), findsOneWidget);
    expect(find.text(l.signInPasswordShort), findsOneWidget);
    verifyNever(() => repo.signInWithEmail(any(), any()));
  });

  testWidgets('email login calls signInWithEmail', (tester) async {
    await pump(tester);
    await fill(tester, ' a@b.co ', 'password1');
    verify(() => repo.signInWithEmail('a@b.co', 'password1')).called(1);
  });

  testWidgets('sign-up without a session shows the confirm-email state', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(l.signInModeSignUp));
    await tester.pump();
    await fill(tester, 'a@b.co', 'password1');
    verify(() => repo.signUpWithEmail('a@b.co', 'password1')).called(1);
    expect(find.text(l.signInConfirmTitle), findsOneWidget);
    expect(find.text(l.signInConfirmBody('a@b.co')), findsOneWidget);
  });

  testWidgets('Google button hidden when no client id', (tester) async {
    await pump(tester, google: false);
    expect(find.text(l.signInGoogle), findsNothing);
    expect(find.text(l.signInOrEmail), findsNothing);
  });

  testWidgets('cancelling Google shows nothing', (tester) async {
    await pump(tester);
    await tester.tap(find.text(l.signInGoogle));
    await tester.pump();
    verify(() => repo.signInWithGoogle()).called(1);
    expect(find.byKey(const Key('email')), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(l.genericError), findsNothing);
  });

  testWidgets('platform: google_login off hides the Google button', (
    tester,
  ) async {
    await pump(
      tester,
      config: {
        'features': {'google_login': false},
      },
    );
    expect(find.text(l.signInGoogle), findsNothing);
    expect(find.byKey(const Key('email')), findsOneWidget);
  });

  testWidgets('platform: email_login off hides the email form', (tester) async {
    await pump(
      tester,
      config: {
        'features': {'email_login': false},
      },
    );
    expect(find.text(l.signInGoogle), findsOneWidget);
    expect(find.byKey(const Key('email')), findsNothing);
    expect(find.text(l.signInOrEmail), findsNothing);
  });

  testWidgets('branding: config app name and tagline', (tester) async {
    await pump(
      tester,
      config: {
        'branding': {'app_name_bn': 'মেস খাতা', 'tagline_bn': 'সহজ হিসাব'},
      },
    );
    expect(find.text('মেস খাতা'), findsOneWidget);
    expect(find.text('সহজ হিসাব'), findsOneWidget);
  });
}
