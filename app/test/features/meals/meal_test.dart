import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/dates.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/month/domain/month.dart';

void main() {
  final day = DateTime(2026, 10, 8);
  MealEntry entry({double count = 1, bool off = false, int guests = 0}) =>
      MealEntry(
        memberId: 'm',
        mealTypeId: 't',
        date: day,
        count: count,
        isOff: off,
        guestCount: guests,
      );

  test('tap cycles 1 → ½ → 0 → 1', () {
    var e = entry();
    e = cycleMeal(e);
    expect(e.count, 0.5);
    e = cycleMeal(e);
    expect(e.count, 0);
    e = cycleMeal(e);
    expect(e.count, 1);
  });

  test('cycling an off meal turns it back on at 1, keeping guests', () {
    final e = cycleMeal(entry(count: 0, off: true, guests: 2));
    expect((e.isOff, e.count, e.guestCount), (false, 1.0, 2));
  });

  test('unusual counts restart at 1', () {
    expect(cycleMeal(entry(count: 2)).count, 1);
  });

  test('people counts guests but not an off member', () {
    expect(entry(count: 0.5, guests: 1).people, 1.5);
    expect(entry(off: true, guests: 1).people, 1);
  });

  test('isoDate pads', () {
    expect(isoDate(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('month read models parse numbers and numeric strings', () {
    final t = MonthTotals.fromJson({
      'food_total': 1410,
      'total_meals': 20.5,
      'meal_rate': '68.7804878048780488',
      'extra_total': 500,
      'credit_total': 1500,
    });
    expect(t.mealRate, closeTo(68.7805, 1e-4));
    expect(t.unallocatedFood, isFalse);
    final b = MemberBalance.fromJson({
      'member_id': 'r',
      'display_name': 'Rahim',
      'meals': 12,
      'food_cost': 825.37,
      'extra_cost': 250,
      'credit': 1500,
      'opening_balance': 0,
      'closing_balance': 424.63,
    });
    expect(b.closingBalance, 424.63);
  });
}
