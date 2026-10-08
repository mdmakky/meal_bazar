// Read models over the SQL calculation engine (0004_months.sql).
// The app never computes these figures itself.

class MonthPeriod {
  const MonthPeriod(this.start, this.end);

  final DateTime start;

  /// Exclusive.
  final DateTime end;
}

class MonthTotals {
  const MonthTotals({
    required this.foodTotal,
    required this.totalMeals,
    required this.mealRate,
    required this.extraTotal,
    required this.creditTotal,
  });

  factory MonthTotals.fromJson(Map<String, dynamic> j) => MonthTotals(
    foodTotal: _d(j['food_total']),
    totalMeals: _d(j['total_meals']),
    mealRate: _d(j['meal_rate']),
    extraTotal: _d(j['extra_total']),
    creditTotal: _d(j['credit_total']),
  );

  final double foodTotal;
  final double totalMeals;
  final double mealRate;
  final double extraTotal;
  final double creditTotal;

  /// Food cost exists but nobody has meals yet: nobody can be charged.
  bool get unallocatedFood => totalMeals == 0 && foodTotal > 0;
}

class MemberBalance {
  const MemberBalance({
    required this.memberId,
    required this.displayName,
    required this.meals,
    required this.foodCost,
    required this.extraCost,
    required this.credit,
    required this.openingBalance,
    required this.closingBalance,
  });

  factory MemberBalance.fromJson(Map<String, dynamic> j) => MemberBalance(
    memberId: j['member_id'] as String,
    displayName: j['display_name'] as String,
    meals: _d(j['meals']),
    foodCost: _d(j['food_cost']),
    extraCost: _d(j['extra_cost']),
    credit: _d(j['credit']),
    openingBalance: _d(j['opening_balance']),
    closingBalance: _d(j['closing_balance']),
  );

  final String memberId;
  final String displayName;
  final double meals;
  final double foodCost;
  final double extraCost;
  final double credit;
  final double openingBalance;

  /// Positive = advance, negative = due.
  final double closingBalance;
}

/// Billable meals on one day (`daily_meal_totals`).
typedef DayMeals = ({DateTime date, double meals});

/// One spending line (`expense_by_category`); [isBazar] marks the bazar total.
typedef CategoryTotal = ({String category, double total, bool isBazar});

/// One billing period's live totals (`month_history`).
typedef MonthPoint = ({
  DateTime start,
  double foodTotal,
  double extraTotal,
  double mealRate,
});

DayMeals dayMealsFromJson(Map<String, dynamic> j) =>
    (date: DateTime.parse(j['date'] as String), meals: _d(j['meals']));

CategoryTotal categoryTotalFromJson(Map<String, dynamic> j) => (
  category: j['category'] as String,
  total: _d(j['total']),
  isBazar: j['is_bazar'] as bool,
);

MonthPoint monthPointFromJson(Map<String, dynamic> j) => (
  start: DateTime.parse(j['start_date'] as String),
  foodTotal: _d(j['food_total']),
  extraTotal: _d(j['extra_total']),
  mealRate: _d(j['meal_rate']),
);

// PostgREST returns numeric as a JSON number, or a string for very long values.
double _d(Object? v) => v is num ? v.toDouble() : double.parse(v as String);
