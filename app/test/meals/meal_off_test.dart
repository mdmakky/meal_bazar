import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/meals/presentation/meal_grid.dart';

void main() {
  test('deadlines show on the Asia/Dhaka clock', () {
    // 13:00 UTC = 19:00 Dhaka, whatever the device zone.
    final d = dhakaClock(DateTime.utc(2026, 10, 9, 13));
    expect((d.day, d.hour, d.minute), (9, 19, 0));
    expect(dhakaClock(DateTime.utc(2026, 10, 9, 18, 30)).day, 10);
  });

  test('toggle off keeps guests, on restores 1', () {
    final e = MealEntry(
      memberId: 'm',
      mealTypeId: 't',
      date: DateTime(2026),
      count: 0.5,
      guestCount: 2,
    );
    final off = toggleMealOff(e);
    expect((off.isOff, off.count, off.guestCount), (true, 0.0, 2));
    final on = toggleMealOff(off);
    expect((on.isOff, on.count, on.guestCount), (false, 1.0, 2));
  });
}
