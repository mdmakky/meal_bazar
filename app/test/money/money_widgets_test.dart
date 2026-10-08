import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/money/application/money_providers.dart';
import 'package:meal_bazar/features/money/data/money_repository.dart';
import 'package:meal_bazar/features/money/domain/money.dart';
import 'package:meal_bazar/features/money/presentation/money_screen.dart';
import 'package:meal_bazar/features/money/presentation/money_sheets.dart';
import 'package:meal_bazar/features/money/presentation/months_screen.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:mocktail/mocktail.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

final l = lookupAppLocalizations(const Locale('bn'));

const mess = Mess(
  id: 'mess1',
  name: 'Mirpur Mess',
  monthStartDay: 1,
  currency: '৳',
  mealOffCutoff: '22:00:00',
);

Member member(String id, String name) => Member(
  id: id,
  messId: 'mess1',
  displayName: name,
  role: id == 'me' ? MemberRole.manager : MemberRole.member,
  status: MemberStatus.active,
  joinedOn: DateTime(2026, 10, 1),
);

final members = [member('me', 'Rahim'), member('k', 'Karim')];
final period = MonthPeriod(DateTime(2026, 10, 1), DateTime(2026, 11, 1));
const totals = MonthTotals(
  foodTotal: 1410,
  totalMeals: 20.5,
  mealRate: 68.78,
  extraTotal: 500,
  creditTotal: 1500,
);

late MockMoneyRepository repo;

Future<void> pump(WidgetTester tester, Widget home, {List<Object>? extra}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        moneyRepositoryProvider.overrideWithValue(repo),
        myMembershipsProvider.overrideWith(
          (ref) async => [Membership(member: members.first, mess: mess)],
        ),
        amIManagerProvider.overrideWithValue(true),
        membersProvider.overrideWith((ref, id) async => members),
        currentPeriodProvider.overrideWith((ref, id) async => period),
        monthTotalsProvider.overrideWith((ref, id) async => totals),
        periodTotalsProvider.overrideWith((ref, key) async => (period, totals)),
        expenseCategoriesProvider.overrideWith(
          (ref, id) async => const [
            ExpenseCategory(
              id: 'gas',
              name: 'গ্যাস',
              defaultSplit: SplitMethod.meal,
            ),
            ExpenseCategory(
              id: 'wifi',
              name: 'ওয়াইফাই',
              defaultSplit: SplitMethod.equal,
            ),
          ],
        ),
        memberBalancesProvider.overrideWith(
          (ref, id) async => const [
            MemberBalance(
              memberId: 'k',
              displayName: 'Karim',
              meals: 8.5,
              foodCost: 584.63,
              extraCost: 250,
              credit: 0,
              openingBalance: 0,
              closingBalance: -834.63,
            ),
            MemberBalance(
              memberId: 'me',
              displayName: 'Rahim',
              meals: 12,
              foodCost: 825.37,
              extraCost: 250,
              credit: 1500,
              openingBalance: 0,
              closingBalance: 424.63,
            ),
          ],
        ),
        monthsProvider.overrideWith(
          (ref, id) async => [
            MessMonth(
              id: 'sep',
              start: DateTime(2026, 9, 1),
              end: DateTime(2026, 10, 1),
              closed: true,
            ),
          ],
        ),
        ...?extra?.cast(),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
}

/// A screen with one button that opens [open].
Widget opener(Future<void> Function(BuildContext) open) => Scaffold(
  body: Builder(
    builder: (c) =>
        TextButton(onPressed: () => open(c), child: const Text('open')),
  ),
);

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> tapSave(WidgetTester tester) async {
  final save = find.widgetWithText(AppButton, l.moneySave);
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Bazar(id: 'x', messId: 'x', date: DateTime(2026), amount: 0),
    );
    registerFallbackValue(
      Expense(
        id: 'x',
        messId: 'x',
        date: DateTime(2026),
        categoryId: 'x',
        amount: 0,
        split: SplitMethod.equal,
      ),
    );
    registerFallbackValue(
      Deposit(
        id: 'x',
        messId: 'x',
        memberId: 'x',
        date: DateTime(2026),
        amount: 1,
      ),
    );
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repo = MockMoneyRepository();
    when(() => repo.saveBazar(any())).thenAnswer((_) async {});
    when(() => repo.saveExpense(any())).thenAnswer((_) async {});
    when(() => repo.saveDeposit(any())).thenAnswer((_) async {});
  });

  group('sheets', () {
    testWidgets('bazar from the mess fund: paid_by null', (tester) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '১২৫০.৫০');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Karim'));
      await tapSave(tester);

      final b =
          verify(() => repo.saveBazar(captureAny())).captured.single as Bazar;
      expect(b.messId, 'mess1');
      expect(b.amount, 1250.5);
      expect(b.buyerMemberId, 'k');
      expect(b.paidByMemberId, isNull);
      expect(b.items, isEmpty);
      expect(find.text(l.moneySaved), findsOneWidget);
    });

    testWidgets('bazar from own pocket needs a member, then sets paid_by', (
      tester,
    ) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '300');
      await tester.tap(find.text(l.moneyPaidPocket));
      await tester.pumpAndSettle();
      await tapSave(tester);
      expect(find.text(l.moneyPickMember), findsOneWidget);
      verifyNever(() => repo.saveBazar(any()));

      // Chips: buyer row first, payer row second.
      final payer = find.widgetWithText(ChoiceChip, 'Rahim').last;
      await tester.ensureVisible(payer);
      await tester.pumpAndSettle();
      await tester.tap(payer);
      await tester.pumpAndSettle();
      await tapSave(tester);
      final b =
          verify(() => repo.saveBazar(captureAny())).captured.single as Bazar;
      expect(b.paidByMemberId, 'me');
      expect(b.buyerMemberId, isNull);
    });

    testWidgets('bazar item lines are sent and their sum is a hint', (
      tester,
    ) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await tester.tap(find.text(l.bazarAddItem));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, l.bazarItemName),
        'চাল',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, l.bazarItemPrice),
        '650',
      );
      await tester.pumpAndSettle();
      expect(find.text(l.bazarItemsSum('৳৬৫০')), findsOneWidget);
      await tester.tap(find.text(l.bazarUseSum));
      await tapSave(tester);
      final b =
          verify(() => repo.saveBazar(captureAny())).captured.single as Bazar;
      expect(b.amount, 650);
      expect(b.items.single.name, 'চাল');
      expect(b.items.single.price, 650);
    });

    testWidgets('invalid amount blocks submit', (tester) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '12.345');
      await tapSave(tester);
      expect(find.text(l.moneyAmountInvalid), findsOneWidget);
      verifyNever(() => repo.saveBazar(any()));
    });

    testWidgets('expense takes the category default split', (tester) async {
      await pump(tester, opener(showAddExpenseSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '800');
      await tester.tap(find.widgetWithText(ChoiceChip, 'গ্যাস'));
      await tapSave(tester);
      final e =
          verify(() => repo.saveExpense(captureAny())).captured.single
              as Expense;
      expect(e.categoryId, 'gas');
      expect(e.split, SplitMethod.meal);
      expect(e.paidByMemberId, isNull);
      expect(e.amount, 800);
    });

    testWidgets('deposit: member, method and TrxID', (tester) async {
      await pump(tester, opener(showAddDepositSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '0');
      await tapSave(tester);
      expect(find.text(l.depositAmountPositive), findsOneWidget);
      expect(find.text(l.moneyPickMember), findsOneWidget);

      await tester.enterText(find.byKey(const Key('amount')), '1500');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Karim'));
      expect(find.widgetWithText(TextFormField, l.depositTrxId), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, l.depositBkash));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, l.depositTrxId),
        'AB12CD34',
      );
      await tapSave(tester);
      final d =
          verify(() => repo.saveDeposit(captureAny())).captured.single
              as Deposit;
      expect(d.memberId, 'k');
      expect(d.amount, 1500);
      expect(d.method, PayMethod.bkash);
      expect(d.trxId, 'AB12CD34');
      expect(d.status, DepositStatus.verified);
    });
  });

  testWidgets('balances show due/advance and explain the bill', (tester) async {
    await pump(tester, const MoneyScreen());
    await tester.pumpAndSettle();
    expect(find.text('Karim'), findsOneWidget);
    expect(find.text(l.balanceDue), findsOneWidget);
    expect(find.text(l.balanceAdvance), findsOneWidget);
    final due = tester.widget<Text>(find.text('-৳৮৩৪.৬৩'));
    expect(due.style?.color, AppPalette.light.due);

    await tester.tap(find.text('Rahim'));
    await tester.pumpAndSettle();
    expect(find.text(l.balanceExplainTitle('Rahim')), findsOneWidget);
    expect(find.text('+ ৳১,৫০০'), findsOneWidget);
    expect(find.text('− ৳৮২৫.৩৭'), findsOneWidget);
    expect(find.text('− ৳২৫০'), findsOneWidget);
    expect(find.text(l.balanceFood('১২', '৳৬৮.৭৮')), findsOneWidget);
    expect(find.text('৳৪২৪.৬৩'), findsWidgets);
  });

  group('months', () {
    testWidgets('closing a month needs the confirmation sheet', (tester) async {
      when(() => repo.closeMonth(any(), any())).thenAnswer((_) async => 'oct');
      await pump(tester, const MonthsScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, l.monthClose));
      await tester.pumpAndSettle();
      verifyNever(() => repo.closeMonth(any(), any()));
      expect(find.text(l.monthCloseBody), findsOneWidget);
      expect(find.text('৳৬৮.৭৮'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-close')));
      await tester.pumpAndSettle();
      verify(() => repo.closeMonth('mess1', any())).called(1);
      expect(find.text(l.monthClosedDone), findsOneWidget);
    });

    testWidgets('reopen requires a reason of at least 5 characters', (
      tester,
    ) async {
      when(() => repo.reopenMonth(any(), any())).thenAnswer((_) async {});
      await pump(tester, const MonthsScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, l.monthReopen));
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(AppButton, l.monthReopen);

      await tester.enterText(find.byType(TextFormField), ' ab ');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text(l.monthReopenReasonShort), findsOneWidget);
      verifyNever(() => repo.reopenMonth(any(), any()));

      await tester.enterText(find.byType(TextFormField), 'ভুল বাজার ঠিক করব');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      verify(() => repo.reopenMonth('sep', 'ভুল বাজার ঠিক করব')).called(1);
      expect(find.text(l.monthReopened), findsOneWidget);
    });
  });
}
