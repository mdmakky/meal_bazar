import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations_bn.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/data/auth_repository.dart';
import 'package:meal_bazar/features/auth/presentation/phone_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  final l = AppLocalizationsBn();
  late MockAuthRepository repo;

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PhoneScreen(),
      ),
    ),
  );

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
  });

  testWidgets('invalid phone shows an error and sends nothing', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('phone')), '01212345678');
    await tester.tap(find.text(l.authSendCode));
    await tester.pump();
    expect(find.text(l.authPhoneInvalid), findsOneWidget);
    expect(find.text(l.authCodeTitle), findsNothing);
    verifyNever(() => repo.sendOtp(any()));
  });

  testWidgets('valid phone moves to the code step', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('phone')), '01712345678');
    await tester.tap(find.text(l.authSendCode));
    await tester.pump();
    verify(() => repo.sendOtp('+8801712345678')).called(1);
    expect(find.text(l.authCodeTitle), findsOneWidget);
    expect(find.byKey(const Key('otp')), findsOneWidget);
    expect(find.text(l.authResendIn(30)), findsOneWidget);

    await tester.tap(find.text(l.authChangeNumber));
    await tester.pump();
    expect(find.text(l.authPhoneTitle), findsOneWidget);
  });
}
