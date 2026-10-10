import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/meals/application/meal_providers.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/money/application/money_providers.dart';
import 'package:meal_bazar/features/money/domain/money.dart';
import 'package:meal_bazar/features/recurring/application/recurring_providers.dart';
import 'package:meal_bazar/features/recurring/data/recurring_repository.dart';
import 'package:meal_bazar/features/recurring/domain/recurring.dart';
import 'package:meal_bazar/features/recurring/presentation/meal_defaults_screen.dart';
import 'package:meal_bazar/features/recurring/presentation/recurring_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringRepository extends Mock implements RecurringRepository {}

const rent = RecurringExpense(
  id: 'r1',
  messId: 'mess1',
  categoryId: 'c-rent',
  amount: 12000,
  split: SplitMethod.equal,
  note: 'ভাড়া',
  dayOfPeriod: 5,
);

Member member(String id, String name, {bool manager = false}) => Member(
  id: id,
  messId: 'mess1',
  displayName: name,
  role: manager ? MemberRole.manager : MemberRole.member,
  status: MemberStatus.active,
  joinedOn: DateTime(2026),
);

void main() {
  late MockRecurringRepository repo;
  setUpAll(() {
    registerFallbackValue(rent);
    registerFallbackValue((memberId: '', mealTypeId: ''));
  });
  setUp(() {
    repo = MockRecurringRepository();
    when(() => repo.bills(any())).thenAnswer((_) async => [rent]);
    when(() => repo.saveBill(any())).thenAnswer((_) async {});
    when(() => repo.pendingCount(any(), any())).thenAnswer((_) async => 4);
  });

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    bool manager = true,
  }) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recurringRepositoryProvider.overrideWithValue(repo),
          myMembershipsProvider.overrideWith(
            (ref) async => [
              Membership(
                member: member('me', 'Rahim', manager: manager),
                mess: const Mess(
                  id: 'mess1',
                  name: 'Mess',
                  monthStartDay: 1,
                  currency: '৳',
                  mealOffCutoff: '22:00:00',
                ),
              ),
            ],
          ),
          amIManagerProvider.overrideWithValue(manager),
          expenseCategoriesProvider.overrideWith(
            (ref, _) async => const [
              ExpenseCategory(
                id: 'c-rent',
                name: 'বাসা ভাড়া',
                defaultSplit: SplitMethod.equal,
              ),
              ExpenseCategory(
                id: 'c-gas',
                name: 'গ্যাস',
                defaultSplit: SplitMethod.meal,
              ),
            ],
          ),
          membersProvider.overrideWith(
            (ref, _) async => [
              member('me', 'Rahim', manager: true),
              member('k', 'Karim'),
            ],
          ),
          mealTypesProvider.overrideWith(
            (ref, _) async => const [
              MealType(
                id: 'b',
                messId: 'mess1',
                name: 'সকাল',
                sortOrder: 0,
                weight: 0.5,
                enabled: false,
              ),
              MealType(
                id: 'l',
                messId: 'mess1',
                name: 'দুপুর',
                sortOrder: 1,
                weight: 1,
                enabled: true,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: home),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('bill payload matches recurring_expenses columns', () {
    final json = rent.toJson();
    expect(json, {
      'id': 'r1',
      'mess_id': 'mess1',
      'category_id': 'c-rent',
      'amount': 12000.0,
      'split': 'equal',
      'note': 'ভাড়া',
      'active': true,
      'day_of_period': 5,
    });
    final back = RecurringExpense.fromJson({...json, 'amount': '12000.00'});
    expect(back.amount, 12000);
    expect(back.dayOfPeriod, 5);
    expect(back.copyWith(active: false).toJson()['active'], false);
  });

  group('RecurringScreen', () {
    testWidgets('lists bills and toggles active', (tester) async {
      await pump(tester, const RecurringScreen());
      expect(find.text('বাসা ভাড়া'), findsOneWidget);
      expect(find.textContaining('মাসের ৫ নম্বর দিন'), findsOneWidget);
      expect(find.textContaining('সমান'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      final saved =
          verify(() => repo.saveBill(captureAny())).captured.single
              as RecurringExpense;
      expect(saved.id, 'r1');
      expect(saved.active, false);
      expect(saved.amount, 12000);
    });

    testWidgets('explains what monthly bills are', (tester) async {
      await pump(tester, const RecurringScreen());
      final l = AppLocalizations.of(
        tester.element(find.byType(RecurringScreen)),
      );
      expect(find.text(l.splitMemBillsHelp), findsOneWidget);
    });

    testWidgets('who shares: loads saved members and persists changes', (
      tester,
    ) async {
      when(() => repo.bills(any())).thenAnswer(
        (_) async => [
          RecurringExpense.fromJson({
            ...rent.toJson(),
            'recurring_expense_members': [
              {'member_id': 'k', 'weight': '2.00'},
            ],
          }),
        ],
      );
      await pump(tester, const RecurringScreen());
      expect(find.textContaining('১ জনের মধ্যে'), findsOneWidget);

      await tester.tap(find.text('বাসা ভাড়া'));
      await tester.pumpAndSettle();
      final boxes = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .map((c) => c.value)
          .toList();
      expect(boxes, [false, true]); // Rahim off, Karim on

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('সেভ করুন'));
      await tester.pumpAndSettle();
      final b =
          verify(() => repo.saveBill(captureAny())).captured.single
              as RecurringExpense;
      expect(b.shares, {'me': 1.0, 'k': 2.0});
    });

    testWidgets('Everyone saves no member rows', (tester) async {
      await pump(tester, const RecurringScreen());
      await tester.tap(find.text('বাসা ভাড়া'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('সেভ করুন'));
      await tester.pumpAndSettle();
      final b =
          verify(() => repo.saveBill(captureAny())).captured.single
              as RecurringExpense;
      expect(b.shares, isEmpty);
    });

    testWidgets('posts this month and reports the count', (tester) async {
      when(() => repo.apply('mess1', any())).thenAnswer((_) async => 2);
      await pump(tester, const RecurringScreen());
      await tester.tap(find.text('এই মাসের বিল বসান'));
      await tester.pumpAndSettle();
      expect(find.text('২টি বিল খরচে বসানো হলো'), findsOneWidget);
    });

    testWidgets('says when nothing was left to post', (tester) async {
      when(() => repo.apply('mess1', any())).thenAnswer((_) async => 0);
      await pump(tester, const RecurringScreen());
      await tester.tap(find.text('এই মাসের বিল বসান'));
      await tester.pumpAndSettle();
      expect(
        find.text('এই মাসের সব নিয়মিত বিল আগেই বসানো হয়েছে'),
        findsOneWidget,
      );
    });

    testWidgets('adds a bill; category sets the split', (tester) async {
      await pump(tester, const RecurringScreen());
      await tester.tap(find.text('নতুন নিয়মিত বিল'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('সেভ করুন'));
      await tester.pumpAndSettle();
      expect(find.text('কিসের খরচ সেটা বেছে নিন'), findsOneWidget);
      verifyNever(() => repo.saveBill(any()));

      await tester.enterText(find.byKey(const Key('amount')), '১৫০০');
      await tester.tap(find.widgetWithText(ChoiceChip, 'গ্যাস'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('সেভ করুন'));
      await tester.pumpAndSettle();

      final b =
          verify(() => repo.saveBill(captureAny())).captured.single
              as RecurringExpense;
      expect(b.toJson()..remove('id'), {
        'mess_id': 'mess1',
        'category_id': 'c-gas',
        'amount': 1500.0,
        'split': 'meal',
        'note': null,
        'active': true,
        'day_of_period': 1,
      });
    });

    testWidgets('members see a lock', (tester) async {
      await pump(tester, const RecurringScreen(), manager: false);
      expect(
        find.text('শুধু ম্যানেজার নিয়মিত বিল বদলাতে পারেন'),
        findsOneWidget,
      );
      verifyNever(() => repo.bills(any()));
    });
  });

  group('MealDefaultsScreen', () {
    testWidgets('steps a member default by half', (tester) async {
      when(
        () => repo.mealDefaults('mess1'),
      ).thenAnswer((_) async => {(memberId: 'k', mealTypeId: 'l'): 0.5});
      when(
        () => repo.setMealDefault(any(), any(), any()),
      ).thenAnswer((_) async {});
      await pump(tester, const MealDefaultsScreen());

      expect(find.text('Rahim'), findsOneWidget);
      expect(find.text('Karim'), findsOneWidget);
      // Disabled breakfast is not shown; one stepper per member.
      expect(find.text('সকাল'), findsNothing);
      expect(find.text('দুপুর'), findsNWidgets(2));
      expect(find.text('১'), findsOneWidget); // Rahim: no default → 1
      expect(find.text('০.৫'), findsOneWidget); // Karim's saved default

      await tester.tap(find.byTooltip('বাড়ান দুপুর').last);
      await tester.pumpAndSettle();
      verify(
        () => repo.setMealDefault('mess1', (memberId: 'k', mealTypeId: 'l'), 1),
      ).called(1);
    });
  });
}
