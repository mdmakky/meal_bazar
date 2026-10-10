import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations_bn.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/data/auth_repository.dart';
import 'package:meal_bazar/features/auth/presentation/reset_code_screen.dart';
import 'package:meal_bazar/features/auth/presentation/sign_in_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;

import '../platform/fixed_config.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  final l = AppLocalizationsBn();
  late MockAuthRepository repo;

  Future<void> pump(WidgetTester tester, String start) async {
    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(
          path: '/auth/sign-in',
          builder: (_, _) => const SignInScreen(googleEnabled: false),
        ),
        GoRoute(
          path: '/auth/reset-code',
          builder: (_, s) => ResetCodeScreen(email: s.extra! as String),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          platformConfig(const {}),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));
  }

  Future<void> fillReset(WidgetTester tester, String code) async {
    await tester.enterText(find.byKey(const Key('resetCode')), code);
    await tester.enterText(find.byKey(const Key('newPassword')), 'password1');
    await tester.enterText(
      find.byKey(const Key('confirmPassword')),
      'password1',
    );
    await tester.tap(find.byKey(const Key('savePassword')));
    await tester.pump();
  }

  setUpAll(() => registerFallbackValue(OtpType.signup));

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.sendPasswordReset(any())).thenAnswer((_) async {});
    when(() => repo.resendSignupCode(any())).thenAnswer((_) async {});
    when(() => repo.updatePassword(any())).thenAnswer((_) async {});
    when(
      () => repo.verifyEmailOtp(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => repo.signUpWithEmail(any(), any()),
    ).thenAnswer((_) async => false);
  });

  testWidgets('forgot password opens the code screen with the email', (
    tester,
  ) async {
    await pump(tester, '/auth/sign-in');
    await tester.enterText(find.byKey(const Key('email')), 'a@b.co');
    await tester.ensureVisible(find.text(l.signInForgot));
    await tester.tap(find.text(l.signInForgot));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    verify(() => repo.sendPasswordReset('a@b.co')).called(1);
    expect(find.text(l.authCodeEmailSentTo('a@b.co')), findsOneWidget);
  });

  testWidgets('reset by code: verify(recovery) then updatePassword', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const ResetCodeScreen(email: 'a@b.co'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await fillReset(tester, '12345678');
    verifyInOrder([
      () => repo.verifyEmailOtp('a@b.co', '12345678', OtpType.recovery),
      () => repo.updatePassword('password1'),
    ]);

    // Wrong code: error shown, password not changed again.
    clearInteractions(repo);
    when(
      () => repo.verifyEmailOtp(any(), any(), any()),
    ).thenAnswer((_) async => throw const AppFailure(FailureKind.invalidOtp));
    await tester.tap(find.byKey(const Key('savePassword')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('resetCodeFailure')), findsOneWidget);
    expect(find.text(l.failureInvalidOtp), findsOneWidget);
    verifyNever(() => repo.updatePassword(any()));

    // Resend: disabled during the cooldown, enabled after 60 s.
    TextButton link() => tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const Key('resendCode')),
        matching: find.byType(TextButton),
      ),
    );
    expect(link().onPressed, isNull);
    await tester.pump(const Duration(seconds: 60));
    expect(link().onPressed, isNotNull);
    await tester.ensureVisible(find.byKey(const Key('resendCode')));
    await tester.tap(find.byKey(const Key('resendCode')));
    await tester.pump();
    verify(() => repo.sendPasswordReset('a@b.co')).called(1);
    await tester.pump();
    expect(link().onPressed, isNull);
    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('sign-up confirm state verifies the code (signup)', (
    tester,
  ) async {
    await pump(tester, '/auth/sign-in');
    await tester.tap(find.text(l.signInModeSignUp));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('email')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('password')), 'password1');
    await tester.ensureVisible(find.byKey(const Key('submit')));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    await tester.pump();
    await tester.enterText(find.byKey(const Key('signupCode')), '123456');
    await tester.tap(find.byKey(const Key('confirmCode')));
    await tester.pump();
    verify(
      () => repo.verifyEmailOtp('a@b.co', '123456', OtpType.signup),
    ).called(1);
    await tester.pump(const Duration(seconds: 61));
  });
}
