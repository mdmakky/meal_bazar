import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations_bn.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/data/auth_repository.dart';
import 'package:meal_bazar/features/auth/presentation/set_new_password_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  final l = AppLocalizationsBn();
  late MockAuthRepository repo;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    // Keep the flag alive like the router does; the link already fired.
    container.listen(passwordRecoveryProvider, (_, _) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SetNewPasswordScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester, String pw, String confirm) async {
    await tester.enterText(find.byKey(const Key('newPassword')), pw);
    await tester.enterText(find.byKey(const Key('confirmPassword')), confirm);
    await tester.tap(find.byKey(const Key('savePassword')));
    await tester.pump();
  }

  setUp(() {
    repo = MockAuthRepository();
    when(
      () => repo.passwordRecoveryEvents(),
    ).thenAnswer((_) => Stream.value(null));
    when(() => repo.updatePassword(any())).thenAnswer((_) async {});
  });

  testWidgets('short password is blocked', (tester) async {
    await pump(tester);
    await submit(tester, 'short', 'short');
    expect(find.text(l.signInPasswordShort), findsOneWidget);
    verifyNever(() => repo.updatePassword(any()));
  });

  testWidgets('mismatched confirmation is blocked', (tester) async {
    await pump(tester);
    await submit(tester, 'password1', 'password2');
    expect(find.text(l.resetMismatch), findsOneWidget);
    verifyNever(() => repo.updatePassword(any()));
    expect(container.read(passwordRecoveryProvider), isTrue);
  });

  testWidgets('valid password is saved and recovery ends', (tester) async {
    await pump(tester);
    expect(container.read(passwordRecoveryProvider), isTrue);
    await submit(tester, 'password1', 'password1');
    verify(() => repo.updatePassword('password1')).called(1);
    expect(find.text(l.resetDone), findsOneWidget);
    expect(container.read(passwordRecoveryProvider), isFalse);
  });
}
