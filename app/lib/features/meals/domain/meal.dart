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

/// Tap cycle for a meal cell: 1 → ½ → 0 → 1. Off and other values restart at 1.
MealEntry cycleMeal(MealEntry e) {
  if (e.isOff) return e.copyWith(isOff: false, count: 1);
  final next = switch (e.count) {
    1 => 0.5,
    0.5 => 0.0,
    _ => 1.0,
  };
  return e.copyWith(count: next);
}
