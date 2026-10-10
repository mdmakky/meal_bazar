import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/shopping/data/shopping_repository.dart';
import 'package:meal_bazar/features/shopping/domain/shopping.dart';
import 'package:meal_bazar/features/shopping/presentation/shopping_screens.dart';
import 'package:mocktail/mocktail.dart';

class MockShopping extends Mock implements ShoppingRepository {}

class FixedMess extends CurrentMessId {
  @override
  String? build() => 'mess1';
}

Member member(String id, String name, {MemberRole role = MemberRole.member}) =>
    Member(
      id: id,
      messId: 'mess1',
      displayName: name,
      role: role,
      status: MemberStatus.active,
      joinedOn: DateTime(2026),
    );

final boss = member('m-boss', 'Boss', role: MemberRole.manager);
final shopper = member('m-rahim', 'Rahim');

ShoppingList sample({String status = 'open', String? reject}) => ShoppingList(
  id: 'l1',
  messId: 'mess1',
  createdBy: 'm-boss',
  assigneeId: 'm-rahim',
  date: DateTime(2026, 10, 10),
  status: status,
  rejectReason: reject,
  items: const [
    ShoppingItem(
      id: 'i1',
      listId: 'l1',
      name: 'চাল',
      qty: 5,
      unit: 'কেজি',
      sort: 1,
    ),
    ShoppingItem(
      id: 'i2',
      listId: 'l1',
      name: 'ডিম',
      qty: 2,
      unit: 'ডজন',
      sort: 2,
    ),
  ],
);

void main() {
  late MockShopping repo;

  setUpAll(() {
    registerFallbackValue(const ShoppingItem(id: 'x', listId: 'x', name: 'x'));
  });

  setUp(() {
    repo = MockShopping();
    when(() => repo.upsertItem(any())).thenAnswer((_) async {});
    when(() => repo.lists(any())).thenAnswer((_) async => [sample()]);
    when(
      () => repo.submit(any(), ownPocket: any(named: 'ownPocket')),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpApp(WidgetTester tester, Widget child, Member me) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repo),
          currentMessIdProvider.overrideWith(FixedMess.new),
          currentMembershipProvider.overrideWithValue(Membership(member: me)),
          amIManagerProvider.overrideWithValue(me.isActiveManager),
          membersProvider('mess1').overrideWith((ref) async => [boss, shopper]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('the total is the ticked, priced items', () {
    final l = sample().copyWith(
      items: [
        const ShoppingItem(
          id: 'a',
          listId: 'l1',
          name: 'a',
          bought: true,
          price: 600,
        ),
        const ShoppingItem(
          id: 'b',
          listId: 'l1',
          name: 'b',
          bought: true,
          price: 220,
        ),
        const ShoppingItem(id: 'c', listId: 'l1', name: 'c', price: 90),
      ],
    );
    expect(l.total, 820);
    expect(l.boughtCount, 2);
    expect(l.shopperId, 'm-rahim');
  });

  testWidgets('the shopper ticks, prices and sends the list as a bazar', (
    tester,
  ) async {
    when(() => repo.list('l1')).thenAnswer((_) async => sample());
    await pumpApp(tester, const ShoppingListScreen(id: 'l1'), shopper);
    expect(find.text('চাল'), findsOneWidget);
    expect(find.byKey(const Key('shop-submit')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('shop-price-i1')), '600');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('shop-price-i2')), '220');
    await tester.pump();
    // Writing a price ticks the item; the total adds them up.
    expect(
      tester.widget<Checkbox>(find.byKey(const Key('shop-tick-i1'))).value,
      isTrue,
    );
    expect(find.text('৳820'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shop-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I paid from my own pocket'));
    await tester.pumpAndSettle();
    verify(() => repo.submit('l1', ownPocket: true)).called(1);
    // Both prices were saved before it was sent.
    verify(() => repo.upsertItem(any())).called(greaterThanOrEqualTo(2));
  });

  testWidgets('nothing priced: the list is not sent', (tester) async {
    when(() => repo.list('l1')).thenAnswer((_) async => sample());
    await pumpApp(tester, const ShoppingListScreen(id: 'l1'), shopper);
    await tester.tap(find.byKey(const Key('shop-submit')));
    await tester.pumpAndSettle();
    expect(
      find.text('Tick at least one item and write its price'),
      findsOneWidget,
    );
    verifyNever(() => repo.submit(any(), ownPocket: any(named: 'ownPocket')));
  });

  testWidgets('a rejected list says why and is open again', (tester) async {
    when(
      () => repo.list('l1'),
    ).thenAnswer((_) async => sample(reject: 'wrong price'));
    await pumpApp(tester, const ShoppingListScreen(id: 'l1'), shopper);
    expect(find.byKey(const Key('shop-rejected')), findsOneWidget);
    expect(find.text('Not accepted: wrong price'), findsOneWidget);
  });

  testWidgets('a submitted list is read-only', (tester) async {
    when(
      () => repo.list('l1'),
    ).thenAnswer((_) async => sample(status: 'submitted'));
    await pumpApp(tester, const ShoppingListScreen(id: 'l1'), shopper);
    expect(find.byKey(const Key('shop-submitted')), findsOneWidget);
    expect(find.byKey(const Key('shop-submit')), findsNothing);
    expect(find.byKey(const Key('shop-add-item')), findsNothing);
  });

  testWidgets(
    'the Bazar tab lists them; a manager can send a list to a member',
    (tester) async {
      when(
        () => repo.saveList(
          id: any(named: 'id'),
          messId: any(named: 'messId'),
          date: any(named: 'date'),
          title: any(named: 'title'),
          note: any(named: 'note'),
          assigneeId: any(named: 'assigneeId'),
        ),
      ).thenAnswer((_) async {});
      when(() => repo.list(any())).thenAnswer((_) async => sample());
      await pumpApp(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: ShoppingSection(messId: 'mess1')),
        ),
        boss,
      );
      expect(find.byKey(const Key('shop-l1')), findsOneWidget);
      expect(
        find.text('For Rahim'),
        findsNothing,
      ); // in the subtitle, with the progress
      await tester.tap(find.byKey(const Key('shop-new')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shop-assign')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rahim').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shop-create')));
      await tester.pumpAndSettle();
      final c = verify(
        () => repo.saveList(
          id: any(named: 'id'),
          messId: 'mess1',
          date: any(named: 'date'),
          title: any(named: 'title'),
          note: any(named: 'note'),
          assigneeId: captureAny(named: 'assigneeId'),
        ),
      ).captured;
      expect(c.single, 'm-rahim');
    },
  );
}
