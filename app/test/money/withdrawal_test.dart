import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/failure_text.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';
import 'package:meal_bazar/features/money/domain/money.dart';
import 'package:meal_bazar/features/money/presentation/money_screen.dart';
import 'package:meal_bazar/features/money/presentation/money_sheets.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'money_widgets_test.dart' hide main;

Deposit payback() => Deposit(
  id: 'w',
  messId: 'mess1',
  memberId: 'k',
  date: DateTime(2026, 10, 3),
  amount: -800,
  kind: 'withdrawal',
);

void main() {
  setUpAll(() {
    registerFallbackValue(PayMethod.cash);
    registerFallbackValue(period);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      Deposit(
        id: 'x',
        messId: 'x',
        memberId: 'x',
        date: DateTime(2026),
        amount: 1,
      ),
    );
  });

  setUp(() {
    activeMess = mess;
    repo = MockMoneyRepository();
    storage = MockStorage();
    when(
      () => repo.recordWithdrawal(
        messId: any(named: 'messId'),
        id: any(named: 'id'),
        memberId: any(named: 'memberId'),
        date: any(named: 'date'),
        amount: any(named: 'amount'),
        method: any(named: 'method'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
    when(() => repo.deleteDeposit(any())).thenAnswer((_) async {});
    when(
      () => repo.deposits(any(), any(), from: any(named: 'from')),
    ).thenAnswer((_) async => [payback()]);
  });

  test('model: kind and the negative amount parse as SQL gives them', () {
    final d = Deposit.fromJson({
      'id': 'w',
      'mess_id': 'm',
      'member_id': 'k',
      'date': '2026-10-03',
      'amount': '-800.00',
      'method': 'cash',
      'status': 'verified',
      'kind': 'withdrawal',
    });
    expect(d.isWithdrawal, isTrue);
    expect(d.amount, -800);
    final plain = Deposit.fromJson({
      'id': 'd',
      'mess_id': 'm',
      'member_id': 'k',
      'date': '2026-10-03',
      'amount': 5,
      'method': 'cash',
      'status': 'verified',
    });
    expect(plain.isWithdrawal, isFalse);
  });

  testWidgets('error keys map to their own messages', (tester) async {
    expect(
      mapError(
        const PostgrestException(message: 'WITHDRAWAL_EXCEEDS_BALANCE'),
      ).kind,
      FailureKind.withdrawalExceeds,
    );
    expect(
      mapError(const PostgrestException(message: 'AMOUNT_INVALID')).kind,
      FailureKind.amountInvalid,
    );
    late BuildContext ctx;
    await pump(
      tester,
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    );
    expect(
      failureText(ctx, const AppFailure(FailureKind.withdrawalExceeds)),
      l.withdrawFailExceeds,
    );
  });

  group('sheet', () {
    Future<void> open(WidgetTester tester, {double? cash}) async {
      await pump(
        tester,
        opener((c) => showWithdrawalSheet(c, member: members.first)),
        extra: [
          messCashProvider.overrideWith(
            (ref, id) async => cash == null
                ? null
                : (
                    depositsIn: cash,
                    fundSpent: 0.0,
                    cash: cash,
                    pendingDeposits: 0.0,
                  ),
          ),
        ],
      );
      await openSheet(tester);
    }

    testWidgets('defaults to the member and shows what they are owed', (
      tester,
    ) async {
      await open(tester);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Rahim'))
            .selected,
        isTrue,
      );
      expect(find.text(l.withdrawOwed('৳৪২৪.৬৩')), findsOneWidget);
    });

    testWidgets('more than the balance is refused', (tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const Key('amount')), '500');
      await tapSave(tester);
      expect(find.text(l.withdrawOverBalance), findsOneWidget);
      verifyNever(
        () => repo.recordWithdrawal(
          messId: any(named: 'messId'),
          id: any(named: 'id'),
          memberId: any(named: 'memberId'),
          date: any(named: 'date'),
          amount: any(named: 'amount'),
          method: any(named: 'method'),
          note: any(named: 'note'),
        ),
      );
    });

    testWidgets(
      'fund note appears but never blocks; save sends a positive amount',
      (tester) async {
        await open(tester, cash: 100);
        expect(find.byKey(const Key('withdraw-fund-note')), findsNothing);
        await tester.enterText(find.byKey(const Key('amount')), '300');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('withdraw-fund-note')), findsOneWidget);
        await tester.tap(find.widgetWithText(ChoiceChip, l.depositBkash));
        await tester.pumpAndSettle();
        await tapSave(tester);
        final c = verify(
          () => repo.recordWithdrawal(
            messId: captureAny(named: 'messId'),
            id: captureAny(named: 'id'),
            memberId: captureAny(named: 'memberId'),
            date: captureAny(named: 'date'),
            amount: captureAny(named: 'amount'),
            method: captureAny(named: 'method'),
            note: captureAny(named: 'note'),
          ),
        ).captured;
        expect(c[0], 'mess1');
        expect(c[2], 'me');
        expect(c[4], 300);
        expect(c[5], PayMethod.bkash);
        expect(find.text(l.withdrawDone), findsOneWidget);
      },
    );
  });

  group('deposits list', () {
    Future<void> tab(WidgetTester tester, {required bool manager}) async {
      await pump(tester, const MoneyScreen(), manager: manager);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.moneyTabDeposit));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'a payback shows the tag and a minus amount; tap opens the detail, not the edit form',
      (tester) async {
        await tab(tester, manager: true);
        expect(find.text(l.withdrawTag), findsOneWidget);
        expect(find.textContaining('-৳'), findsOneWidget);
        await tester.tap(find.text(l.withdrawRowTitle('Karim')));
        await tester.pumpAndSettle();
        expect(find.text(l.withdrawDetailTitle), findsOneWidget);
        expect(find.text(l.depositEdit), findsNothing);
        // Delete is confirmed, then goes through the soft-delete path.
        await tester.tap(find.widgetWithText(AppButton, l.delete));
        await tester.pumpAndSettle();
        expect(find.text(l.withdrawDeleteBody), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(l.delete),
          ),
        );
        await tester.pumpAndSettle();
        verify(() => repo.deleteDeposit('w')).called(1);
      },
    );

    testWidgets('the pay-back action is a manager thing', (tester) async {
      await tab(tester, manager: true);
      expect(find.text(l.withdrawAction), findsOneWidget);
    });

    testWidgets('members see the row but no entry point and no delete', (
      tester,
    ) async {
      await tab(tester, manager: false);
      expect(find.text(l.withdrawTag), findsOneWidget);
      expect(find.text(l.withdrawAction), findsNothing);
      await tester.tap(find.text(l.withdrawRowTitle('Karim')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppButton, l.delete), findsNothing);
    });
  });
}
