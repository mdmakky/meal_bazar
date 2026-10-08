// Recurring monthly bills and default meals (0015_recurring_and_templates.sql).

import '../../money/domain/money.dart';

/// A `recurring_expenses` row: a bill posted once per billing period.
class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.messId,
    required this.categoryId,
    required this.amount,
    required this.split,
    this.note,
    this.active = true,
    this.dayOfPeriod = 1,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> j) => RecurringExpense(
    id: j['id'] as String,
    messId: j['mess_id'] as String,
    categoryId: j['category_id'] as String,
    amount: double.parse('${j['amount']}'), // numeric may arrive as text
    split: SplitMethod.values.byName(j['split'] as String),
    note: j['note'] as String?,
    active: j['active'] as bool,
    dayOfPeriod: j['day_of_period'] as int,
  );

  final String id;
  final String messId;
  final String categoryId;
  final double amount;
  final SplitMethod split;
  final String? note;
  final bool active;

  /// 1–28: posted on period start + this − 1.
  final int dayOfPeriod;

  RecurringExpense copyWith({bool? active}) => RecurringExpense(
    id: id,
    messId: messId,
    categoryId: categoryId,
    amount: amount,
    split: split,
    note: note,
    active: active ?? this.active,
    dayOfPeriod: dayOfPeriod,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'category_id': categoryId,
    'amount': amount,
    'split': split.name,
    'note': note,
    'active': active,
    'day_of_period': dayOfPeriod,
  };
}

/// `meal_defaults` keyed by (member, meal type).
typedef MealDefaultKey = ({String memberId, String mealTypeId});
