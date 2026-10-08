import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/ids.dart';
import 'package:meal_bazar/features/money/domain/bazar_catalogue.dart';
import 'package:meal_bazar/features/money/domain/money.dart';
import 'package:meal_bazar/features/month/domain/month.dart';

void main() {
  test('parseAmount accepts ≥0 with at most 2 decimals, Bangla digits', () {
    expect(parseAmount('250'), 250);
    expect(parseAmount(' 250.5 '), 250.5);
    expect(parseAmount('0'), 0);
    expect(parseAmount('১,৪১০.৫০'), 1410.5);
    expect(parseAmount(''), isNull);
    expect(parseAmount('-5'), isNull);
    expect(parseAmount('1.234'), isNull);
    expect(parseAmount('1.'), isNull);
    expect(parseAmount('abc'), isNull);
    expect(parseAmount('10000000000'), isNull);
  });

  test('sharePreview splits by weight, rounded to paisa', () {
    expect(sharePreview(900, {'a': 1, 'b': 1, 'c': 1}), {
      'a': 300,
      'b': 300,
      'c': 300,
    });
    expect(sharePreview(900, {'a': 2, 'b': 1}), {'a': 600, 'b': 300});
    expect(sharePreview(100, {'a': 1, 'b': 1, 'c': 1})['a'], 33.33);
    expect(sharePreview(100, {}), isEmpty);
  });

  test('Expense parses and serialises shares', () {
    final e = Expense.fromJson({
      'id': 'e',
      'mess_id': 'm',
      'date': '2026-10-05',
      'category_id': 'c',
      'amount': '900.00',
      'split': 'equal',
      'expense_shares': [
        {'member_id': 'a', 'weight': '2.00'},
        {'member_id': 'b', 'weight': 1},
      ],
    });
    expect(e.shares, {'a': 2.0, 'b': 1.0});
    expect(e.sharesJson().first, {'member_id': 'a', 'weight': 2.0});
  });

  test('itemsTotal sums exactly in paisa', () {
    expect(itemsTotal([0.1, 0.2]), 0.3);
    expect(itemsTotal([]), 0);
  });

  test(
    'bill lines add up to the closing balance (PRODUCT_RULES §3 fixture)',
    () {
      const rahim = MemberBalance(
        memberId: 'r',
        displayName: 'Rahim',
        meals: 12,
        foodCost: 825.37,
        extraCost: 250,
        credit: 1500,
        openingBalance: 0,
        closingBalance: 424.63,
      );
      final lines = billLines(rahim);
      expect(lines.map((l) => l.part), BillPart.values);
      expect(lines.firstWhere((l) => l.part == BillPart.food).amount, -825.37);
      final sum = lines.fold<double>(0, (s, l) => s + l.amount);
      expect(sum, closeTo(rahim.closingBalance, 0.001));
    },
  );

  test('uuidV4 is a v4 UUID', () {
    final id = uuidV4();
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(id),
      isTrue,
    );
    expect(uuidV4(), isNot(id));
  });

  test('frequent items: most bought first, ties by name, top n, trimmed', () {
    final names = [
      'ডিম',
      ' চাল ',
      'ডিম',
      'আলু',
      'চাল',
      'ডিম',
      '',
      'মুরগি',
      'আলু',
      'পেঁয়াজ',
      'লবণ',
      'তেল',
      'চিনি',
    ];
    expect(frequentItems(names), [
      'ডিম',
      'আলু',
      'চাল',
      ...(['চিনি', 'তেল', 'পেঁয়াজ', 'মুরগি', 'লবণ']..sort()).take(3),
    ]);
    expect(frequentItems(names, n: 1), ['ডিম']);
    expect(frequentItems(const []), isEmpty);
  });

  test('catalogue units', () {
    expect(catalogueUnit('ডিম'), 'হালি');
    expect(catalogueUnit('সয়াবিন তেল'), 'লিটার');
    expect(catalogueUnit('কিছু একটা'), isNull);
  });
}
