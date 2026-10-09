import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/failure_text.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/storage.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/money/application/bazar_request_providers.dart';
import 'package:meal_bazar/features/money/application/money_providers.dart';
import 'package:meal_bazar/features/money/data/bazar_request_repository.dart';
import 'package:meal_bazar/features/money/data/money_repository.dart';
import 'package:meal_bazar/features/money/domain/bazar_request.dart';
import 'package:meal_bazar/features/money/domain/money.dart';
import 'package:meal_bazar/features/money/presentation/money_screen.dart';
import 'package:meal_bazar/features/money/presentation/money_sheets.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockRequests extends Mock implements BazarRequestRepository {}

class MockStorage extends Mock implements StorageService {}

final l = lookupAppLocalizations(const Locale('bn'));

const mess = Mess(
  id: 'mess1',
  name: 'Mirpur Mess',
  monthStartDay: 1,
  currency: '৳',
  mealOffCutoff: '22:00:00',
);

Member member(
  String id,
  String name, {
  MemberRole role = MemberRole.member,
  MemberStatus status = MemberStatus.active,
}) => Member(
  id: id,
  messId: 'mess1',
  displayName: name,
  role: role,
  status: status,
  joinedOn: DateTime(2026, 10, 1),
);

final rahim = member('r', 'Rahim', role: MemberRole.manager);
final karim = member('k', 'Karim');
final salam = member('s', 'Salam');
final gone = member('x', 'Old', status: MemberStatus.inactive);

BazarRequest req(
  String id, {
  BazarRequestStatus status = BazarRequestStatus.pending,
  String? reason,
}) => BazarRequest(
  id: id,
  messId: 'mess1',
  memberId: 'k',
  date: DateTime(2026, 10, 5),
  amount: 450,
  buyerIds: const ['k', 's'],
  items: const [
    BazarItem(id: 'i1', name: 'আলু', price: 150, qty: 2, unit: 'কেজি'),
    BazarItem(id: 'i2', name: 'ডিম', price: 300),
  ],
  status: status,
  rejectReason: reason,
);

late MockMoneyRepository money;
late MockRequests requests;

Future<void> pump(WidgetTester tester, Widget home, {required Member me}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        moneyRepositoryProvider.overrideWithValue(money),
        bazarRequestRepositoryProvider.overrideWithValue(requests),
        myMembershipsProvider.overrideWith(
          (ref) async => [Membership(member: me, mess: mess)],
        ),
        amIManagerProvider.overrideWithValue(me.isActiveManager),
        storageServiceProvider.overrideWithValue(MockStorage()),
        membersProvider.overrideWith(
          (ref, id) async => [rahim, karim, salam, gone],
        ),
        currentPeriodProvider.overrideWith(
          (ref, id) async =>
              MonthPeriod(DateTime(2026, 10, 1), DateTime(2026, 11, 1)),
        ),
        spendingByCategoryProvider.overrideWith((ref, id) async => const []),
        monthsProvider.overrideWith((ref, id) async => const []),
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

Widget opener(Future<void> Function(BuildContext) open) => Scaffold(
  body: Builder(
    builder: (c) =>
        TextButton(onPressed: () => open(c), child: const Text('open')),
  ),
);

/// Scrolls the bazar page until [f] is on screen.
Future<void> reveal(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f,
    200,
    scrollable: find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> tapIt(WidgetTester tester, Finder f) async {
  await reveal(tester, f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      BazarRequest(id: 'x', messId: 'x', date: DateTime(2026), amount: 1),
    );
    registerFallbackValue(
      MonthPeriod(DateTime(2026, 10, 1), DateTime(2026, 11, 1)),
    );
  });

  setUp(() {
    money = MockMoneyRepository();
    requests = MockRequests();
    when(() => money.itemNames(any())).thenAnswer((_) async => []);
    when(
      () => money.bazars(any(), any(), from: any(named: 'from')),
    ).thenAnswer((_) async => []);
    when(() => requests.submit(any())).thenAnswer((_) async {});
    when(() => requests.cancel(any())).thenAnswer((_) async {});
    when(
      () => requests.review(
        any(),
        approve: any(named: 'approve'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async {});
    when(() => requests.pending(any())).thenAnswer((_) async => []);
    when(() => requests.mine(any(), any())).thenAnswer((_) async => []);
  });

  group('model', () {
    test('parses a row (numeric strings, items, status, reason)', () {
      final r = BazarRequest.fromJson({
        'id': 'q1',
        'mess_id': 'mess1',
        'member_id': 'k',
        'date': '2026-10-05',
        'amount': '450.50',
        'own_pocket': false,
        'buyer_ids': ['k', 's'],
        'items': [
          {'name': 'আলু', 'qty': 2, 'unit': 'কেজি', 'price': 150},
          {'name': 'ডিম', 'qty': null, 'unit': null, 'price': '300.5'},
        ],
        'note': 'হাট',
        'receipt_path': null,
        'status': 'rejected',
        'reject_reason': 'রসিদ নেই',
      });
      expect(r.amount, 450.5);
      expect(r.ownPocket, false);
      expect(r.buyerIds, ['k', 's']);
      expect(r.items.map((i) => (i.name, i.qty, i.unit, i.price)), [
        ('আলু', 2.0, 'কেজি', 150.0),
        ('ডিম', null, null, 300.5),
      ]);
      expect(r.status, BazarRequestStatus.rejected);
      expect(r.rejectReason, 'রসিদ নেই');
      expect(r.asBazar().paidByMemberId, isNull, reason: 'mess fund');
    });

    test('submit params match the RPC signature', () {
      expect(req('q1').params(), {
        'p_mess': 'mess1',
        'p_id': 'q1',
        'p_date': '2026-10-05',
        'p_amount': 450.0,
        'p_own_pocket': true,
        'p_buyer_ids': ['k', 's'],
        'p_items': [
          {'name': 'আলু', 'qty': 2.0, 'unit': 'কেজি', 'price': 150.0},
          {'name': 'ডিম', 'qty': null, 'unit': null, 'price': 300.0},
        ],
        'p_note': null,
        'p_receipt_path': null,
      });
      expect(req('q1').asBazar().paidByMemberId, 'k', reason: 'own pocket');
    });

    testWidgets('new error codes have their own text', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('bn'),
          delegates: AppLocalizations.localizationsDelegates,
          child: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      String t(String key) =>
          failureText(ctx, PostgrestException(message: key, code: 'P0001'));
      expect(t('FUTURE_DATE'), l.bazarReqFailFutureDate);
      expect(t('BAZAR_REQUEST_NOT_PENDING'), l.bazarReqFailNotPending);
      expect(t('ITEMS_INVALID'), l.bazarReqFailItemsInvalid);
      expect(
        mapError(
          const PostgrestException(message: 'FUTURE_DATE', code: 'P0001'),
        ).kind,
        FailureKind.futureDate,
      );
    });
  });

  group('submission sheet', () {
    String amount(WidgetTester tester) => tester
        .widget<TextFormField>(find.byKey(const Key('amount')))
        .controller!
        .text;

    bool amountLocked(WidgetTester tester) => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('amount')),
            matching: find.byType(TextField),
          ),
        )
        .readOnly;

    Future<void> send(WidgetTester tester) async {
      final b = find.widgetWithText(AppButton, l.bazarReqSend);
      await tester.ensureVisible(b);
      await tester.tap(b);
      await tester.pumpAndSettle();
    }

    BazarRequest sent() =>
        verify(() => requests.submit(captureAny())).captured.single
            as BazarRequest;

    testWidgets('me first and fixed; companions; items sum into the amount', (
      tester,
    ) async {
      await pump(tester, opener(showBazarRequestForm), me: karim);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(l.bazarReqTitle), findsOneWidget);
      expect(find.text(l.bazarScan), findsNothing);

      // The submitter leads and cannot be unpicked; inactive members hide.
      final first = tester.widget<FilterChip>(find.byType(FilterChip).first);
      expect((first.label as Text).data, 'Karim');
      expect(first.selected, isTrue);
      await tester.tap(find.byKey(const Key('companion-me')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('companion-me')))
            .selected,
        isTrue,
      );
      expect(find.widgetWithText(FilterChip, 'Old'), findsNothing);
      await tapIt(tester, find.widgetWithText(FilterChip, 'Salam'));

      // No items yet: the amount is typed.
      expect(amountLocked(tester), isFalse);
      await tester.enterText(find.byKey(const Key('amount')), '300');

      // An item with a price: the amount follows the sum and locks.
      final search = find.byKey(const Key('picker-search'));
      await reveal(tester, search);
      await tester.enterText(search, 'আলু');
      await tester.pumpAndSettle();
      await tapIt(tester, find.widgetWithText(FilterChip, 'আলু'));
      final price = find.byKey(const Key('item-price'));
      await reveal(tester, price);
      await tester.enterText(price, '60');
      await tester.pumpAndSettle();
      expect(amount(tester), '৬০');
      expect(amountLocked(tester), isTrue);

      await send(tester);
      final r = sent();
      expect(r.messId, 'mess1');
      expect(r.buyerIds, ['k', 's']);
      expect(r.ownPocket, isTrue);
      expect(r.amount, 60);
      expect(r.items.single.name, 'আলু');
      expect(find.text(l.bazarReqSent), findsOneWidget);
    });

    testWidgets('an amount is required; mess fund can be chosen', (
      tester,
    ) async {
      await pump(tester, opener(showBazarRequestForm), me: karim);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await send(tester);
      verifyNever(() => requests.submit(any()));
      expect(find.text(l.moneyAmountInvalid), findsOneWidget);

      await tester.enterText(find.byKey(const Key('amount')), '০');
      await send(tester);
      verifyNever(() => requests.submit(any()));

      await tester.enterText(find.byKey(const Key('amount')), '২৫০');
      await tapIt(tester, find.text(l.bazarReqMessFund));
      await send(tester);
      final r = sent();
      expect(r.amount, 250);
      expect(r.ownPocket, isFalse);
      expect(r.buyerIds, ['k']);
      expect(r.items, isEmpty);
    });

    testWidgets('a server refusal stays on the page with its text', (
      tester,
    ) async {
      when(
        () => requests.submit(any()),
      ).thenThrow(const AppFailure(FailureKind.futureDate));
      await pump(tester, opener(showBazarRequestForm), me: karim);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('amount')), '100');
      await send(tester);
      expect(find.text(l.bazarReqFailFutureDate), findsOneWidget);
      expect(find.text(l.bazarReqTitle), findsOneWidget);
    });
  });

  group('bazar tab', () {
    testWidgets('manager reviews a pending bazar and accepts it', (
      tester,
    ) async {
      when(
        () => requests.pending('mess1'),
      ).thenAnswer((_) async => [req('q1')]);
      await pump(tester, const BazarScreen(), me: rahim);
      await tester.pumpAndSettle();
      expect(find.text(l.bazarReqReview), findsOneWidget);
      expect(find.text('Karim'), findsOneWidget);
      expect(find.text('৳৪৫০'), findsOneWidget);
      expect(find.textContaining(l.bazarReqWithNames('Salam')), findsOneWidget);
      expect(find.text(l.bazarReqFab), findsNothing);

      await tester.tap(find.text('Karim'));
      await tester.pumpAndSettle();
      expect(find.text(l.bazarReqOf('Karim')), findsOneWidget);
      expect(find.textContaining('আলু'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, l.bazarReqApprove));
      await tester.pumpAndSettle();
      verify(
        () => requests.review('q1', approve: true, reason: null),
      ).called(1);
      expect(find.text(l.bazarReqApproveDone), findsOneWidget);
      // The approved bazar list reloads.
      verify(
        () => money.bazars('mess1', any(), from: 0),
      ).called(greaterThan(1));
    });

    testWidgets('manager returns a bazar with a reason', (tester) async {
      when(
        () => requests.pending('mess1'),
      ).thenAnswer((_) async => [req('q1')]);
      await pump(tester, const BazarScreen(), me: rahim);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karim'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, l.bazarReqReject));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('reject-reason')),
        'রসিদ নেই',
      );
      await tester.tap(find.widgetWithText(FilledButton, l.bazarReqReject));
      await tester.pumpAndSettle();
      verify(
        () => requests.review('q1', approve: false, reason: 'রসিদ নেই'),
      ).called(1);
      expect(find.text(l.bazarReqRejectDone), findsOneWidget);
    });

    testWidgets('member: submit button, own list with status, no withdraw', (
      tester,
    ) async {
      when(() => requests.mine('mess1', 'k')).thenAnswer(
        (_) async => [
          req('q1'),
          req('q2', status: BazarRequestStatus.rejected, reason: 'রসিদ নেই'),
        ],
      );
      await pump(tester, const BazarScreen(), me: karim);
      await tester.pumpAndSettle();
      expect(find.text(l.bazarReqFab), findsOneWidget);
      expect(find.text(l.bazarAdd), findsNothing);
      expect(find.text(l.bazarReqMine), findsOneWidget);
      expect(find.text(l.bazarReqPending), findsOneWidget);
      expect(find.text(l.bazarReqRejected), findsOneWidget);
      expect(find.textContaining(l.bazarReqReason('রসিদ নেই')), findsOneWidget);
      verifyNever(() => requests.pending(any()));

      await tester.tap(find.text(l.bazarReqPending));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppButton, l.bazarReqApprove), findsNothing);
      expect(find.widgetWithText(AppButton, l.bazarReqCancel), findsNothing);
      verifyNever(() => requests.cancel(any()));
    });
  });
}
