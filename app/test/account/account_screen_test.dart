import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/account/data/account_repository.dart';
import 'package:meal_bazar/features/account/presentation/account_screen.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/data/auth_repository.dart';
import 'package:meal_bazar/features/auth/domain/profile.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeProfile extends MyProfileNotifier {
  @override
  Future<Profile?> build() async =>
      const Profile(id: 'u1', fullName: 'Rahim', locale: 'bn');
}

final l = lookupAppLocalizations(const Locale('bn'));

void main() {
  late MockAccountRepository account;
  late MockAuthRepository auth;

  setUp(() {
    account = MockAccountRepository();
    auth = MockAuthRepository();
    when(() => account.deleteMyAccount()).thenAnswer((_) async {});
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(account),
          authRepositoryProvider.overrideWithValue(auth),
          myProfileProvider.overrideWith(FakeProfile.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton confirmButton(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('deleteConfirmButton')));

  /// The delete row sits below the fold; scroll the page to it, then tap.
  Future<void> tapDelete(WidgetTester tester) async {
    final row = find.byKey(const Key('deleteAccount'));
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(row);
  }

  testWidgets('deletion requires typing the confirm word, then signs out', (
    tester,
  ) async {
    await pump(tester);
    expect(find.widgetWithText(TextField, 'Rahim'), findsOneWidget);

    await tapDelete(tester);
    await tester.pumpAndSettle();
    expect(find.text(l.accountDeleteKept), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('deleteConfirmField')), 'মুছ');
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNull);
    verifyNever(() => account.deleteMyAccount());

    await tester.enterText(
      find.byKey(const Key('deleteConfirmField')),
      'মুছুন',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('deleteConfirmButton')));
    await tester.pumpAndSettle();

    verify(() => account.deleteMyAccount()).called(1);
    verify(() => auth.signOut()).called(1);
  });

  testWidgets('last manager refusal is shown and keeps the session', (
    tester,
  ) async {
    when(
      () => account.deleteMyAccount(),
    ).thenThrow(const AppFailure(FailureKind.lastManager));
    await pump(tester);

    await tapDelete(tester);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('deleteConfirmField')),
      'মুছুন',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('deleteConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.text(l.failureLastManager), findsOneWidget);
    verifyNever(() => auth.signOut());
  });
}
