/// Matches `meal_types` (PRODUCT_RULES §1).
class MealType {
  const MealType({
    required this.id,
    required this.messId,
    required this.name,
    required this.sortOrder,
    required this.weight,
    required this.enabled,
  });

  factory MealType.fromJson(Map<String, dynamic> json) => MealType(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    name: json['name'] as String,
    sortOrder: json['sort_order'] as int,
    weight: (json['weight'] as num).toDouble(),
    enabled: json['enabled'] as bool,
  );

  final String id;
  final String messId;
  final String name;
  final int sortOrder;
  final double weight;
  final bool enabled;
}

/// One member × day × meal type. No row means 0 meals.
class MealEntry {
  const MealEntry({
    required this.memberId,
    required this.mealTypeId,
    required this.date,
    this.count = 1,
    this.guestCount = 0,
    this.isOff = false,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
    memberId: json['member_id'] as String,
    mealTypeId: json['meal_type_id'] as String,
    date: DateTime.parse(json['date'] as String),
    count: (json['count'] as num).toDouble(),
    guestCount: json['guest_count'] as int,
    isOff: json['is_off'] as bool,
  );

  final String memberId;
  final String mealTypeId;
  final DateTime date;
  final double count;
  final int guestCount;
  final bool isOff;

  MealEntry copyWith({double? count, int? guestCount, bool? isOff}) =>
      MealEntry(
        memberId: memberId,
        mealTypeId: mealTypeId,
        date: date,
        count: count ?? this.count,
        guestCount: guestCount ?? this.guestCount,
        isOff: isOff ?? this.isOff,
      );

  /// Display-only; SQL `member_meal_totals` is the source of truth for billing.
  double get people => (isOff ? 0.0 : count) + guestCount;
}

/// Tap cycle for a meal value: 0 → 0.5 → 1 → 1.5 → 2 → 0. Off counts as 0;
/// anything above 2 (set with the stepper) restarts at 0. Guests are kept.
MealEntry cycleMeal(MealEntry e) {
  final c = e.isOff ? 0.0 : e.count;
  return e.copyWith(isOff: false, count: c >= 2 ? 0 : c + 0.5);
}

/// Stepper: ±0.5 within 0–5. Leaving "off" starts from 0.
MealEntry stepMeal(MealEntry e, double delta) {
  final c = e.isOff ? 0.0 : e.count;
  return e.copyWith(isOff: false, count: (c + delta).clamp(0, 5).toDouble());
}

/// Member self-service toggle: off ↔ on (1). Guests are kept.
MealEntry toggleMealOff(MealEntry e) => e.isOff
    ? e.copyWith(isOff: false, count: 1)
    : e.copyWith(isOff: true, count: 0);

/// When a member can no longer switch [date]'s meal off: the previous day at
/// `messes.meal_off_cutoff` ('HH:MM[:SS]'), Asia/Dhaka (UTC+6, no DST).
/// UX only; SQL `set_my_meal_off` enforces it.
DateTime mealOffDeadline(DateTime date, String cutoff) {
  final p = cutoff.split(':').map(int.parse).toList();
  return DateTime.utc(date.year, date.month, date.day - 1, p[0] - 6, p[1]);
}
