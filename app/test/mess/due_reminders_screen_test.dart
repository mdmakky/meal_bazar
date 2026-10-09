import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/data/mess_repository.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/mess/presentation/due_reminders_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockMessRepository extends Mock implements MessRepository {}

final l = lookupAppLocalizations(const Locale('bn'));

const mess = Mess(
  id: 'mess1',
  name: 'Mirpur Mess',
  monthStartDay: 1,
  currency: '৳',
  mealOffCutoff: '22:00:00',
);

late MockMessRepository repo;

Future<void> pump(WidgetTester tester) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      messRepositoryProvider.overrideWithValue(repo),
      myMembershipsProvider.overrideWith(
        (ref) async => [
          Membership(
            member: Member(
              id: 'me',
              messId: 'mess1',
              displayName: 'Karim',
              role: MemberRole.manager,
              status: MemberStatus.active,
              joinedOn: DateTime(2026, 10, 1),
              userId: 'u1',
            ),
            mess: mess,
          ),
        ],
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('bn'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DueRemindersScreen(),
    ),
  ),
);

void main() {
  setUpAll(() => registerFallbackValue((id: 'x', body: 'x')));

  setUp(() {
    repo = MockMessRepository();
    when(() => repo.dueReminderTexts('mess1')).thenAnswer((_) async => []);
    when(
      () => repo.setDueReminders(
        any(),
        every: any(named: 'every'),
        min: any(named: 'min'),
      ),
    ).thenAnswer((_) async => mess);
    when(() => repo.saveDueReminderText(any(), any())).thenAnswer((_) async {});
  });

  testWidgets('the switch saves; a frequency chip saves', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dueRemEvery-7')), findsNothing);

    await tester.tap(find.byKey(const Key('dueRemSwitch')));
    await tester.pumpAndSettle();
    verify(() => repo.setDueReminders('mess1', every: 3, min: 0)).called(1);

    await tester.tap(find.byKey(const ValueKey('dueRemEvery-7')));
    await tester.pumpAndSettle();
    verify(() => repo.setDueReminders('mess1', every: 7, min: 0)).called(1);
  });

  testWidgets('empty: a suggestion adds with one tap', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(l.dueRemTextsEmpty), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dueRemSuggest-0')));
    await tester.pumpAndSettle();
    final saved =
        verify(
              () => repo.saveDueReminderText('mess1', captureAny()),
            ).captured.single
            as DueReminderText;
    expect(saved.body, l.dueRemSuggest1('{name}', '{amount}'));
  });

  testWidgets('add a text with a live preview', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dueRemAdd')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('dueRemText')),
      '{name}, {amount} বাকি — {mess}',
    );
    await tester.pump();
    expect(find.text('রহিম, ৳৫০০ বাকি — Mirpur Mess'), findsOneWidget);

    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    final saved =
        verify(
              () => repo.saveDueReminderText('mess1', captureAny()),
            ).captured.single
            as DueReminderText;
    expect(saved.body, '{name}, {amount} বাকি — {mess}');
  });

  testWidgets('lists the texts', (tester) async {
    when(
      () => repo.dueReminderTexts('mess1'),
    ).thenAnswer((_) async => [(id: 't1', body: 'জমা দিন {name}')]);
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('জমা দিন {name}'), findsOneWidget);
    expect(find.text(l.dueRemTextsEmpty), findsNothing);
  });
}
