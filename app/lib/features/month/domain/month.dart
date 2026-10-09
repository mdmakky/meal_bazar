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
    this.fixedRate = false,
    this.rateGap = 0,
  });

  /// `month_totals`, optionally merged with `month_rate_info` (0016) for
  /// `mode` and `surplus_or_deficit`.
  factory MonthTotals.fromJson(Map<String, dynamic> j) => MonthTotals(
    foodTotal: _d(j['food_total']),
    totalMeals: _d(j['total_meals']),
    mealRate: _d(j['meal_rate']),
    extraTotal: _d(j['extra_total']),
    creditTotal: _d(j['credit_total']),
    fixedRate: j['mode'] == 'fixed',
    rateGap: j['surplus_or_deficit'] == null ? 0 : _d(j['surplus_or_deficit']),
  );

  final double foodTotal;
  final double totalMeals;
  final double mealRate;
  final double extraTotal;
  final double creditTotal;

  /// A fixed rate is in force: [mealRate] is that rate, not food ÷ meals.
  final bool fixedRate;

  /// Fixed mode only: food_total − rate × total_meals, reported never
  /// charged. > 0 = bazar cost more than the rate collected.
  final double rateGap;

  /// Food cost exists but nobody has meals yet: nobody can be charged.
  bool get unallocatedFood => !fixedRate && totalMeals == 0 && foodTotal > 0;
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

/// Manager Home "needs attention" (`manager_attention`).
typedef Attention = ({
  int pendingDeposits,
  int pendingMembers,
  int mealsMissing,
  int pendingRecurring,
  int pendingBazarRequests,
});

Attention attentionFromJson(Map<String, dynamic> j) => (
  pendingDeposits: j['pending_deposits'] as int,
  pendingMembers: j['pending_members'] as int,
  mealsMissing: j['meals_missing'] as int,
  pendingRecurring: j['pending_recurring'] as int,
  // Older servers (before 0026) have no such column.
  pendingBazarRequests: j['pending_bazar_requests'] as int? ?? 0,
);

/// The mess fund for a period (`mess_cash`): verified deposits − fund-paid.
typedef MessCash = ({
  double depositsIn,
  double fundSpent,
  double cash,
  double pendingDeposits,
});

MessCash messCashFromJson(Map<String, dynamic> j) => (
  depositsIn: _d(j['deposits_in']),
  fundSpent: _d(j['fund_spent']),
  cash: _d(j['cash']),
  pendingDeposits: _d(j['pending_deposits']),
);

/// One member in the transparency table (`member_transparency`).
typedef MemberTransparency = ({
  String memberId,
  String displayName,
  double deposits,
  double ownPocket,
  double closingBalance,
});

MemberTransparency memberTransparencyFromJson(Map<String, dynamic> j) => (
  memberId: j['member_id'] as String,
  displayName: j['display_name'] as String,
  deposits: _d(j['deposits']),
  ownPocket: _d(j['own_pocket']),
  closingBalance: _d(j['closing_balance']),
);

/// The caller's previous period (`my_last_month`). The money figures are
/// the caller's final snapshot once closed, provisional before that.
class LastMonth {
  const LastMonth({
    required this.start,
    required this.end,
    required this.closed,
    this.provisional = false,
    this.reopenedAt,
    this.meals,
    this.foodCost,
    this.extraCost,
    this.credit,
    this.openingBalance,
    this.closingBalance,
  });

  factory LastMonth.fromJson(Map<String, dynamic> j) {
    double? n(String k) => j[k] == null ? null : _d(j[k]);
    return LastMonth(
      start: DateTime.parse(j['start_date'] as String),
      end: DateTime.parse(j['end_date'] as String),
      closed: j['status'] == 'closed',
      // Older servers (before 0032) have no such column.
      provisional: j['provisional'] == true,
      reopenedAt: j['reopened_at'] == null
          ? null
          : DateTime.parse(j['reopened_at'] as String).toLocal(),
      meals: n('meals'),
      foodCost: n('food_cost'),
      extraCost: n('extra_cost'),
      credit: n('credit'),
      openingBalance: n('opening_balance'),
      closingBalance: n('closing_balance'),
    );
  }

  final DateTime start;

  /// Exclusive: the first day of the current period.
  final DateTime end;
  final bool closed;

  /// The figures are not frozen yet (the month is open or being corrected).
  final bool provisional;

  /// Set while a reopened month is being corrected.
  final DateTime? reopenedAt;
  final double? meals;
  final double? foodCost;
  final double? extraCost;
  final double? credit;
  final double? openingBalance;

  /// Positive = advance, negative = due.
  final double? closingBalance;
}

/// The period waiting to be closed (`month_review`, 0032).
class MonthStatus {
  const MonthStatus({
    required this.start,
    required this.end,
    required this.status,
    this.closedAt,
    this.reopenedAt,
    this.closedMissing = 0,
    required this.totals,
    this.pendingDeposits = 0,
    this.pendingBazarRequests = 0,
    this.missingDays = 0,
    this.autoState = 'off',
    this.autoBadDays = 0,
    this.totalsReconstructed = false,
    this.openingProvisional = false,
    this.canClose = false,
  });

  factory MonthStatus.fromJson(Map<String, dynamic> j) => MonthStatus(
    start: DateTime.parse(j['start_date'] as String),
    end: DateTime.parse(j['end_date'] as String),
    status: j['status'] as String,
    closedAt: j['closed_at'] == null
        ? null
        : DateTime.parse(j['closed_at'] as String).toLocal(),
    reopenedAt: j['reopened_at'] == null
        ? null
        : DateTime.parse(j['reopened_at'] as String).toLocal(),
    closedMissing: (j['closed_missing'] as num?)?.toInt() ?? 0,
    totals: MonthTotals.fromJson({
      for (final k in const [
        'food_total',
        'total_meals',
        'meal_rate',
        'extra_total',
        'credit_total',
      ])
        k: j[k] ?? 0,
    }),
    pendingDeposits: (j['pending_deposits'] as num?)?.toInt() ?? 0,
    pendingBazarRequests: (j['pending_bazar_requests'] as num?)?.toInt() ?? 0,
    missingDays: (j['missing_days'] as num?)?.toInt() ?? 0,
    autoState: j['auto_state'] as String? ?? 'off',
    autoBadDays: (j['auto_bad_days'] as num?)?.toInt() ?? 0,
    totalsReconstructed: j['totals_reconstructed'] == true,
    openingProvisional: j['opening_provisional'] == true,
    canClose: j['can_close'] == true,
  );

  final DateTime start;

  /// Exclusive.
  final DateTime end;

  /// 'open' | 'correcting' | 'closed'.
  final String status;
  final DateTime? closedAt;
  final DateTime? reopenedAt;
  final int closedMissing;
  final MonthTotals totals;
  final int pendingDeposits;
  final int pendingBazarRequests;

  /// Missing member-days (a member with no entry on a day).
  final int missingDays;

  /// 'off' | 'ok' | 'pending' | 'incomplete' | 'failed'.
  final String autoState;
  final int autoBadDays;
  final bool totalsReconstructed;
  final bool openingProvisional;
  final bool canClose;

  bool get isClosed => status == 'closed';
  bool get isCorrecting => status == 'correcting';
  bool get autoBlocks =>
      const {'pending', 'incomplete', 'failed'}.contains(autoState);

  /// Something a manager should look at (the chip turns "needs attention").
  bool get needsAttention =>
      pendingDeposits + pendingBazarRequests > 0 ||
      missingDays > 0 ||
      (autoState != 'ok' && autoState != 'off');
}

/// A member with no meal entry on [day] (`month_missing_meals`).
typedef MissingMeal = ({DateTime day, String memberId, String name});

MissingMeal missingMealFromJson(Map<String, dynamic> j) => (
  day: DateTime.parse(j['day'] as String),
  memberId: j['member_id'] as String,
  name: j['display_name'] as String,
);

/// Pending items that block closing a period (`month_pending_items`).
typedef PendingItems = ({int deposits, int bazarRequests});

PendingItems pendingItemsFromJson(Map<String, dynamic> j) => (
  deposits: j['pending_deposits'] as int,
  bazarRequests: j['pending_bazar_requests'] as int,
);

/// Member lists for a period: a member who left shows only while the period
/// still has something of theirs ([figures] are its SQL numbers).
bool shownInPeriod({required bool left, required Iterable<double> figures}) =>
    !left || figures.any((v) => v != 0);

/// Dues first (most owed first), then advances (largest first), settled last.
int duesFirst(double a, double b) {
  int rank(double v) => v < 0 ? 0 : (v > 0 ? 1 : 2);
  final r = rank(a).compareTo(rank(b));
  if (r != 0) return r;
  return a < 0 ? a.compareTo(b) : b.compareTo(a);
}

// PostgREST returns numeric as a JSON number, or a string for very long values.
double _d(Object? v) => v is num ? v.toDouble() : double.parse(v as String);
