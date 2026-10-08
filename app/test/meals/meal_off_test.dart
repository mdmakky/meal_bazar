import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';

void main() {
  test('cutoff is the previous day at the mess time, Asia/Dhaka', () {
    // 22:00 Dhaka on Oct 9 = 16:00 UTC.
    expect(
      mealOffDeadline(DateTime(2026, 10, 10), '22:00:00'),
      DateTime.utc(2026, 10, 9, 16),
    );
    expect(
      mealOffDeadline(DateTime(2026, 11, 1), '05:30'),
      DateTime.utc(2026, 10, 30, 23, 30),
    );
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
