import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/storage.dart';
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

import '../platform/fixed_config.dart';

class MockMoneyRepository extends Mock implements MoneyRepository {}

class MockStorage extends Mock implements StorageService {}

/// A valid 1×1 PNG, so Image.memory can decode it.
final pngBytes = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0B,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x60,
  0x00,
  0x02,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x7A,
  0x5E,
  0xAB,
  0x3F,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

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
late MockStorage storage;

Future<void> pump(
  WidgetTester tester,
  Widget home, {
  List<Object>? extra,
  bool manager = true,
  MonthTotals monthTotals = totals,
}) {
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
        amIManagerProvider.overrideWithValue(manager),
        storageServiceProvider.overrideWithValue(storage),
        receiptPickerProvider.overrideWithValue((_) async => pngBytes),
        membersProvider.overrideWith((ref, id) async => members),
        currentPeriodProvider.overrideWith((ref, id) async => period),
        monthTotalsProvider.overrideWith((ref, id) async => monthTotals),
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

/// Scrolls the bazar page until [f] is on screen (rows below are lazy).
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
    registerFallbackValue(period);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repo = MockMoneyRepository();
    storage = MockStorage();
    when(() => repo.saveBazar(any())).thenAnswer((_) async {});
    when(() => repo.itemNames(any())).thenAnswer((_) async => []);
    when(() => repo.saveExpense(any())).thenAnswer((_) async {});
    when(() => repo.saveDeposit(any())).thenAnswer((_) async {});
  });

  group('sheets', () {
    Future<void> tapIt(WidgetTester tester, Finder f) async {
      await reveal(tester, f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<void> buyer(WidgetTester tester, String name) =>
        tapIt(tester, find.widgetWithText(FilterChip, name));

    /// Finds [name] through the picker's search and toggles its chip.
    Future<void> pick(WidgetTester tester, String name) async {
      final search = find.byKey(const Key('picker-search'));
      await reveal(tester, search);
      await tester.enterText(search, name);
      await tester.pumpAndSettle();
      await tapIt(tester, find.widgetWithText(FilterChip, name));
    }

    Future<void> price(WidgetTester tester, int i, String v) async {
      final f = find.byKey(const Key('item-price')).at(i);
      await reveal(tester, f);
      await tester.enterText(f, v);
      await tester.pumpAndSettle();
    }

    String amount(WidgetTester tester) => tester
        .widget<TextFormField>(find.byKey(const Key('amount')))
        .controller!
        .text;

    Bazar saved() =>
        verify(() => repo.saveBazar(captureAny())).captured.single as Bazar;

    testWidgets('bazar needs a buyer; several buyers, mess fund by default', (
      tester,
    ) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      expect(find.text(l.bazarAdd), findsOneWidget);
      await tester.enterText(find.byKey(const Key('amount')), '১২৫০.৫০');
      await tapSave(tester);
      expect(find.text(l.bazarPickBuyer), findsWidgets);
      verifyNever(() => repo.saveBazar(any()));

      await buyer(tester, 'Karim');
      await buyer(tester, 'Rahim');
      await tapSave(tester);
      final b = saved();
      expect(b.messId, 'mess1');
      expect(b.amount, 1250.5);
      expect(b.buyers, ['k', 'me']);
      expect(b.buyerMemberId, 'k', reason: 'first pick is mirrored');
      expect(b.paidByMemberId, isNull);
      expect(b.items, isEmpty);
      expect(find.text(l.moneySaved), findsOneWidget);
    });

    testWidgets('a buyer can be unpicked; one member pays', (tester) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '300');
      await buyer(tester, 'Karim');
      await buyer(tester, 'Rahim');
      await buyer(tester, 'Karim'); // unpick
      await tapIt(tester, find.widgetWithText(ChoiceChip, 'Karim'));
      expect(find.text(l.moneyPaidPocketHelp), findsOneWidget);
      await tapSave(tester);
      final b = saved();
      expect(b.buyers, ['me']);
      expect(b.paidByMemberId, 'k');
    });

    testWidgets('editing keeps the buyers; delete sits in the overflow', (
      tester,
    ) async {
      when(() => repo.deleteBazar(any())).thenAnswer((_) async {});
      final existing = Bazar(
        id: 'b1',
        messId: 'mess1',
        date: DateTime(2026, 10, 2),
        amount: 120,
        buyers: const ['me', 'k'],
        items: const [
          BazarItem(id: 'i1', name: 'আলু', price: 120, qty: 2, unit: 'কেজি'),
        ],
      );
      await pump(tester, opener((c) => showBazarForm(c, existing: existing)));
      await openSheet(tester);
      expect(find.text(l.bazarEdit), findsOneWidget);
      expect(find.text('২ কেজি'), findsOneWidget);
      expect(find.widgetWithText(AppButton, l.delete), findsNothing);
      await tapSave(tester);
      final b = saved();
      expect(b.id, 'b1');
      expect(b.buyers, ['me', 'k']);
      expect(b.items.single.name, 'আলু');

      await pump(tester, opener((c) => showBazarForm(c, existing: existing)));
      await openSheet(tester);
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.delete).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, l.delete).last);
      await tester.pumpAndSettle();
      verify(() => repo.deleteBazar('b1')).called(1);
    });

    testWidgets('picker: frequent items first, then the catalogue', (
      tester,
    ) async {
      when(
        () => repo.itemNames(any()),
      ).thenAnswer((_) async => ['মুরগি', 'ডিম', 'ডিম', 'বিস্কুট']);
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      // Category tabs; the first (most bought) is open.
      expect(find.text(l.bazarPickerFrequent), findsOneWidget);
      expect(find.text(l.bazarPickerStaples), findsOneWidget);
      expect(find.text(l.bazarPickerSpice), findsOneWidget);
      // A mess's own item that is not in the catalogue.
      expect(find.widgetWithText(FilterChip, 'বিস্কুট'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'চাল'), findsNothing);
      Offset at(String n) =>
          tester.getTopLeft(find.widgetWithText(FilterChip, n));
      final (egg, chicken) = (at('ডিম'), at('মুরগি'));
      expect(
        egg.dy < chicken.dy || (egg.dy == chicken.dy && egg.dx < chicken.dx),
        isTrue,
        reason: 'ডিম (bought twice) reads before মুরগি',
      );

      await tapIt(tester, find.text(l.bazarPickerStaples));
      expect(find.widgetWithText(FilterChip, 'চাল'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'বিস্কুট'), findsNothing);
    });

    testWidgets('picker search finds across tabs and adds a new name', (
      tester,
    ) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      final search = find.byKey(const Key('picker-search'));
      await tester.enterText(search, 'মরিচ');
      await tester.pumpAndSettle();
      // Veg and spice tabs both have a মরিচ.
      expect(find.widgetWithText(FilterChip, 'কাঁচা মরিচ'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'মরিচ গুঁড়া'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'আলু'), findsNothing);

      await tester.enterText(search, 'সাবান');
      await tester.pumpAndSettle();
      await tapIt(tester, find.text(l.bazarPickerAddNamed('সাবান')));
      expect(find.byKey(const Key('item-price')), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('item-name')))
            .controller!
            .text,
        'সাবান',
      );
    });

    testWidgets('picker adds and removes lines; sum fills amount and total', (
      tester,
    ) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await buyer(tester, 'Karim');

      await pick(tester, 'আলু');
      await pick(tester, 'ডিম');
      expect(find.byKey(const Key('item-price')), findsNWidgets(2));
      expect(find.text('১ কেজি'), findsOneWidget);
      expect(find.text('১ হালি'), findsOneWidget);
      await price(tester, 0, '60');
      await price(tester, 1, '50');
      expect(amount(tester), '১১০');
      expect(find.text('৳১১০'), findsOneWidget); // sticky running total

      // Tapping the chip again removes the line and its price.
      await pick(tester, 'আলু');
      expect(find.byKey(const Key('item-price')), findsOneWidget);
      expect(amount(tester), '৫০');
      expect(find.text('৳৫০'), findsOneWidget);

      // The qty stepper, then the unit chooser.
      await tapIt(
        tester,
        find.bySemanticsLabel('${l.mealCellIncrease} ${l.bazarItemQty}'),
      );
      expect(find.text('২ হালি'), findsOneWidget);
      await tapIt(tester, find.text('২ হালি'));
      await tapIt(tester, find.text('ডজন').last);
      expect(find.text('২ ডজন'), findsOneWidget);

      await tapSave(tester);
      final item = saved().items.single;
      expect(
        (item.name, item.qty, item.unit, item.price),
        ('ডিম', 2.0, 'ডজন', 50.0),
      );
    });

    testWidgets('swipe removes a line; undo puts it back', (tester) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await pick(tester, 'আলু');
      await pick(tester, 'ডিম');
      await price(tester, 0, '60');
      await price(tester, 1, '50');
      expect(amount(tester), '১১০');

      await tester.fling(find.text('১ কেজি'), const Offset(-600, 0), 2000);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('item-price')), findsOneWidget);
      expect(amount(tester), '৫০');
      expect(find.text(l.bazarItemRemoved), findsOneWidget);

      await tester.tap(find.text(l.undo));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('item-price')), findsNWidgets(2));
      expect(amount(tester), '১১০');
      final first = tester.widget<TextFormField>(
        find.byKey(const Key('item-name')).first,
      );
      expect(first.controller!.text, 'আলু', reason: 'back in its place');
    });

    testWidgets('a typed amount is kept; the sum becomes a hint', (
      tester,
    ) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '700');
      await pick(tester, 'চাল');
      await price(tester, 0, '650');
      expect(amount(tester), '700');
      expect(find.text(l.bazarItemsSum('৳৬৫০')), findsOneWidget);
      await tapIt(tester, find.text(l.bazarUseSum));
      expect(amount(tester), '৬৫০');
      expect(find.text(l.bazarItemsSum('৳৬৫০')), findsNothing);
    });

    testWidgets('custom item line; a line without a price blocks save', (
      tester,
    ) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await buyer(tester, 'Rahim');
      await tapIt(tester, find.text(l.bazarAddItem));
      await tester.enterText(find.byKey(const Key('item-name')), 'সাবান');
      await tester.pumpAndSettle();
      await tapSave(tester);
      expect(find.text(l.bazarItemInvalid), findsWidgets);
      verifyNever(() => repo.saveBazar(any()));

      await price(tester, 0, '40');
      await tapSave(tester);
      final b = saved();
      expect(b.amount, 40);
      expect(b.items.single.name, 'সাবান');
      expect(b.items.single.qty, 1);
    });

    testWidgets('invalid amount blocks submit', (tester) async {
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '12.345');
      await tapSave(tester);
      expect(find.text(l.moneyAmountInvalid), findsOneWidget);
      verifyNever(() => repo.saveBazar(any()));
    });

    testWidgets('360 dp at 1.3× text: no overflow', (tester) async {
      await pump(tester, opener(showAddBazarSheet));
      tester.view.physicalSize = const Size(1080, 2220); // 360 × 740 dp
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await openSheet(tester);
      await buyer(tester, 'Karim');
      await pick(tester, 'সয়াবিন তেল');
      await price(tester, 0, '১২৫০');
      await tapIt(
        tester,
        find.bySemanticsLabel('${l.mealCellIncrease} ${l.bazarItemQty}'),
      );
      await tapIt(
        tester,
        find.bySemanticsLabel('${l.mealCellDecrease} ${l.bazarItemQty}'),
      );
      await tapIt(
        tester,
        find.bySemanticsLabel('${l.mealCellDecrease} ${l.bazarItemQty}'),
      );
      expect(find.text('০.৫ লিটার'), findsOneWidget);
      await tapIt(tester, find.widgetWithText(ChoiceChip, 'Karim'));
      expect(tester.takeException(), isNull);
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

    testWidgets('expense among selected members: weights and preview', (
      tester,
    ) async {
      await pump(tester, opener(showAddExpenseSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '900');
      await tester.tap(find.widgetWithText(ChoiceChip, 'ওয়াইফাই'));
      await tester.tap(find.text(l.splitSelected));
      await tester.pumpAndSettle();

      // Everyone present starts checked with ভাগ ১: ৳৪৫০ each (preview only).
      final preview = find.byKey(const Key('share-preview'));
      expect(find.text(l.splitPreview), findsOneWidget);
      String shown(num v) => Fmt.money(v, banglaDigits: true);
      expect(
        find.descendant(of: preview, matching: find.text(shown(450))),
        findsNWidgets(2),
      );

      final more = find.byTooltip('${l.splitWeightMore} Rahim');
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.text(l.splitWeight('২')), findsOneWidget);
      expect(
        find.descendant(of: preview, matching: find.text(shown(600))),
        findsOneWidget,
      );
      expect(
        find.descendant(of: preview, matching: find.text(shown(300))),
        findsOneWidget,
      );

      await tapSave(tester);
      final e =
          verify(() => repo.saveExpense(captureAny())).captured.single
              as Expense;
      expect(e.split, SplitMethod.equal);
      expect(e.shares, {'me': 2.0, 'k': 1.0});
      expect(e.sharesJson(), [
        {'member_id': 'me', 'weight': 2.0},
        {'member_id': 'k', 'weight': 1.0},
      ]);
    });

    testWidgets('selected split needs a member; equal split sends no shares', (
      tester,
    ) async {
      await pump(tester, opener(showAddExpenseSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '500');
      await tester.tap(find.widgetWithText(ChoiceChip, 'ওয়াইফাই'));
      await tester.tap(find.text(l.splitSelected));
      await tester.pumpAndSettle();
      for (final i in [0, 1]) {
        final box = find.byType(Checkbox).at(i);
        await tester.ensureVisible(box);
        await tester.tap(box);
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('share-preview')), findsNothing);
      await tapSave(tester);
      expect(find.text(l.splitPickMember), findsOneWidget);
      verifyNever(() => repo.saveExpense(any()));

      await tester.tap(find.text(l.splitEqualAll));
      await tester.pumpAndSettle();
      await tapSave(tester);
      final e =
          verify(() => repo.saveExpense(captureAny())).captured.single
              as Expense;
      expect(e.split, SplitMethod.equal);
      expect(e.shares, isEmpty);
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

    testWidgets('platform: split off hides the selected-members option', (
      tester,
    ) async {
      await pump(
        tester,
        opener(showAddExpenseSheet),
        extra: [
          flagsOff(['split']),
        ],
      );
      await openSheet(tester);
      expect(find.text(l.splitByMeal), findsOneWidget);
      expect(find.text(l.splitSelected), findsNothing);
    });

    testWidgets('platform: catalogue from config; scan and photo hidden', (
      tester,
    ) async {
      await pump(
        tester,
        opener(showAddBazarSheet),
        extra: [
          platformConfig({
            'features': {'ai_bazar_scan': false, 'receipts': false},
            'catalogue': {
              'groups': [
                {
                  'name': 'ফলমূল',
                  'items': [
                    {'name': 'আম', 'unit': 'কেজি'},
                  ],
                },
              ],
            },
          }),
        ],
      );
      await openSheet(tester);
      expect(find.text('ফলমূল'), findsOneWidget);
      expect(find.text(l.bazarPickerStaples), findsNothing);
      expect(find.text(l.bazarScan), findsNothing);
      expect(find.text(l.receiptAttach), findsNothing);
      final chip = find.widgetWithText(FilterChip, 'আম');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(
        find.text('১ কেজি'),
        findsOneWidget,
        reason: 'the config unit fills the line',
      );
    });

    testWidgets('platform: payment methods relabeled and hidden', (
      tester,
    ) async {
      await pump(
        tester,
        opener(showAddDepositSheet),
        extra: [
          platformConfig({
            'payment_methods': [
              {'key': 'bkash', 'label_bn': 'বিকাশ (পার্সোনাল)'},
              {'key': 'bank', 'enabled': false},
            ],
          }),
        ],
      );
      await openSheet(tester);
      expect(
        find.widgetWithText(ChoiceChip, 'বিকাশ (পার্সোনাল)'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ChoiceChip, l.depositBank), findsNothing);
      expect(find.widgetWithText(ChoiceChip, l.depositNagad), findsOneWidget);
    });
  });

  testWidgets('বাজার tab: month total and the list; managers can add', (
    tester,
  ) async {
    when(() => repo.bazars(any(), any(), from: any(named: 'from'))).thenAnswer(
      (_) async => [
        Bazar(
          id: 'b1',
          messId: 'mess1',
          date: DateTime(2026, 10, 2),
          amount: 820,
          buyers: ['k'],
        ),
      ],
    );
    final spending = [
      spendingByCategoryProvider.overrideWith(
        (ref, id) async => const [
          (category: 'বাজার', total: 1410.0, isBazar: true),
        ],
      ),
    ];
    await pump(tester, const BazarScreen(), extra: spending);
    await tester.pumpAndSettle();
    expect(find.text(l.bazarTabTotal), findsOneWidget);
    expect(find.text('৳১,৪১০'), findsOneWidget);
    expect(find.text('Karim'), findsOneWidget);
    expect(find.text('৳৮২০'), findsOneWidget);
    expect(find.text(l.bazarAdd), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await pump(tester, const BazarScreen(), extra: spending, manager: false);
    await tester.pumpAndSettle();
    expect(find.text(l.bazarAdd), findsNothing);
  });

  testWidgets('হিসাব has no bazar sub-tab', (tester) async {
    await pump(tester, const MoneyScreen());
    await tester.pumpAndSettle();
    expect(find.text(l.moneyTabBazar), findsNothing);
    expect(find.text(l.moneyTabExpense), findsOneWidget);
  });

  testWidgets('balances show due/advance and explain the bill', (tester) async {
    await pump(tester, const MoneyScreen());
    await tester.pumpAndSettle();
    expect(find.text('Karim'), findsOneWidget);
    expect(find.text(l.balanceDue), findsOneWidget);
    expect(find.text(l.balanceAdvance), findsOneWidget);
    final due = tester.widget<Text>(find.text('-৳৮৩৪.৬৩'));
    expect(due.style?.color, AppPalette.light.due);
    // My own row is marked; dues come first.
    expect(find.text(l.youTag), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Karim')).dy,
      lessThan(tester.getTopLeft(find.text('Rahim')).dy),
    );

    await tester.tap(find.text('Rahim'));
    await tester.pumpAndSettle();
    expect(find.text(l.balanceExplainTitle('Rahim')), findsOneWidget);
    expect(find.text('+ ৳১,৫০০'), findsOneWidget);
    expect(find.text('− ৳৮২৫.৩৭'), findsOneWidget);
    expect(find.text('− ৳২৫০'), findsOneWidget);
    expect(find.text(l.balanceFood('১২', '৳৬৮.৭৮')), findsOneWidget);
    expect(find.text('৳৪২৪.৬৩'), findsWidgets);
    expect(find.text(l.stampPaid), findsOneWidget); // in advance: stamped
    expect(find.text(l.shareBillShare), findsOneWidget);
  });

  testWidgets('fixed rate: proof, gap line and fixed food line', (
    tester,
  ) async {
    const fixed = MonthTotals(
      foodTotal: 1410,
      totalMeals: 20.5,
      mealRate: 60,
      extraTotal: 500,
      creditTotal: 1500,
      fixedRate: true,
      rateGap: 180,
    );
    await pump(tester, const MoneyScreen(), monthTotals: fixed);
    await tester.pumpAndSettle();
    // The proof opens on tap.
    await tester.tap(find.text('৳৬০'));
    await tester.pumpAndSettle();
    expect(find.text(l.rateFixed), findsOneWidget);
    expect(find.text(l.moneyMealRateProof('৳১,৪১০', '২০½')), findsNothing);
    expect(find.text(l.rateDeficit('৳১৮০')), findsOneWidget);

    await tester.ensureVisible(find.text('Rahim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rahim'));
    await tester.pumpAndSettle();
    expect(find.text(l.rateBalanceFood('১২', '৳৬০')), findsOneWidget);
    expect(
      find.text('খাবার খরচ = ১২ মিল × ৳৬০ (নির্দিষ্ট রেট)'),
      findsOneWidget,
    );
  });

  testWidgets('balances: managers share all; export in the menu', (
    tester,
  ) async {
    await pump(tester, const MoneyScreen());
    await tester.pumpAndSettle();
    expect(find.text(l.shareBillShareAll), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text(l.exportTitle), findsOneWidget);
  });

  testWidgets('balances: members get no share actions', (tester) async {
    await pump(tester, const MoneyScreen(), manager: false);
    await tester.pumpAndSettle();
    expect(find.text(l.shareBillShareAll), findsNothing);
    await tester.tap(find.text('Rahim'));
    await tester.pumpAndSettle();
    expect(find.text(l.balanceExplainTitle('Rahim')), findsOneWidget);
    expect(find.text(l.shareBillShare), findsNothing);
  });

  testWidgets('members: the last row scrolls clear of the FAB at 1.3x', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, const MoneyScreen(), manager: false);
    await tester.pumpAndSettle();
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.text('Rahim')).dy,
      lessThan(tester.getTopLeft(fab).dy),
    );
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
      expect(find.text(l.monthClosedDone), findsWidgets); // card + snack
      expect(find.byType(StampMark), findsOneWidget);
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

  group('receipts and member deposits', () {
    test('receipt path is {messId}/{uuid}.jpg', () {
      expect(
        receiptPath('mess1'),
        matches(
          RegExp(r'^mess1/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}\.jpg$'),
        ),
      );
      expect(receiptPath('mess1'), isNot(receiptPath('mess1')));
    });

    testWidgets('failed upload keeps the sheet open; retry saves the path', (
      tester,
    ) async {
      when(
        () => storage.uploadReceipt(any(), any()),
      ).thenThrow(const AppFailure(FailureKind.network));
      await pump(tester, opener(showAddBazarSheet));
      await openSheet(tester);
      await tester.enterText(find.byKey(const Key('amount')), '200');
      await tester.tap(find.widgetWithText(FilterChip, 'Karim'));
      await tester.pumpAndSettle();
      final attach = find.text(l.receiptAttach);
      await reveal(tester, attach);
      await tester.tap(attach);
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);

      await tapSave(tester);
      expect(find.text(l.networkError), findsOneWidget);
      expect(find.text(l.bazarAdd), findsOneWidget); // page still open
      expect(find.byKey(const Key('amount')), findsOneWidget);
      verifyNever(() => repo.saveBazar(any()));

      when(
        () => storage.uploadReceipt(any(), any()),
      ).thenAnswer((_) async => 'mess1/r.jpg');
      when(
        () => storage.signedUrl(any()),
      ).thenAnswer((_) async => 'https://x/r.jpg');
      await tapSave(tester);
      final b =
          verify(() => repo.saveBazar(captureAny())).captured.single as Bazar;
      expect(b.receiptPath, 'mess1/r.jpg');
      expect(b.amount, 200);
      verify(() => storage.uploadReceipt('mess1', any())).called(2);
    });

    testWidgets('member records own deposit as pending via the RPC', (
      tester,
    ) async {
      when(() => repo.recordMyDeposit(any())).thenAnswer((_) async {});
      when(
        () => storage.uploadReceipt(any(), any()),
      ).thenAnswer((_) async => 'mess1/s.jpg');
      when(
        () => storage.signedUrl(any()),
      ).thenAnswer((_) async => 'https://x/s.jpg');
      await pump(tester, const MoneyScreen(), manager: false);
      await tester.pumpAndSettle();
      expect(find.text(l.depositAdd), findsNothing);
      await tester.tap(find.text(l.depositVerifyMine));
      await tester.pumpAndSettle();
      expect(find.text(l.depositVerifyHelp), findsOneWidget);
      await tester.enterText(find.byKey(const Key('amount')), '৫০০');
      await tester.enterText(
        find.widgetWithText(TextFormField, l.depositTrxId),
        'BK9',
      );
      final shot = find.text(l.receiptScreenshot);
      await tester.ensureVisible(shot);
      await tester.tap(shot);
      await tester.pumpAndSettle();
      await tapSave(tester);

      final d =
          verify(() => repo.recordMyDeposit(captureAny())).captured.single
              as Deposit;
      expect(d.messId, 'mess1');
      expect(d.amount, 500);
      expect(d.method, PayMethod.bkash);
      expect(d.trxId, 'BK9');
      expect(d.status, DepositStatus.pending);
      expect(d.screenshotPath, 'mess1/s.jpg');
      verifyNever(() => repo.saveDeposit(any()));
      expect(find.text(l.depositVerifySent), findsOneWidget);
    });

    Deposit dep(String id, DepositStatus status) => Deposit(
      id: id,
      messId: 'mess1',
      memberId: 'k',
      date: DateTime(2026, 10, 3),
      amount: 700,
      status: status,
    );

    Future<void> depositsTab(
      WidgetTester tester, {
      required bool manager,
    }) async {
      when(
        () => repo.deposits(any(), any(), from: any(named: 'from')),
      ).thenAnswer(
        (_) async => [
          dep('v', DepositStatus.verified),
          dep('p', DepositStatus.pending),
        ],
      );
      await pump(tester, const MoneyScreen(), manager: manager);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.moneyTabDeposit));
      await tester.pumpAndSettle();
    }

    testWidgets('manager verifies pending deposits only, after confirming', (
      tester,
    ) async {
      when(
        () => repo.verifyDeposit(any(), approve: any(named: 'approve')),
      ).thenAnswer((_) async {});
      await depositsTab(tester, manager: true);
      expect(find.textContaining(l.depositPending), findsOneWidget);
      expect(find.widgetWithText(AppButton, l.depositVerifyApprove), findsOne);
      expect(find.widgetWithText(AppButton, l.depositVerifyReject), findsOne);

      await tester.tap(find.widgetWithText(AppButton, l.depositVerifyApprove));
      await tester.pumpAndSettle();
      verifyNever(
        () => repo.verifyDeposit(any(), approve: any(named: 'approve')),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(l.depositVerifyApprove),
        ),
      );
      await tester.pumpAndSettle();
      verify(() => repo.verifyDeposit('p', approve: true)).called(1);
      expect(find.text(l.depositVerifyDone), findsOneWidget);
    });

    testWidgets('members see no verify actions', (tester) async {
      await depositsTab(tester, manager: false);
      expect(
        find.widgetWithText(AppButton, l.depositVerifyApprove),
        findsNothing,
      );
    });
  });
}
