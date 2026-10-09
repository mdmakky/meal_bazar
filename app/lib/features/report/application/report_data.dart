// What the monthly report shows. Money, rates, balances and weighted meal
// totals come from SQL (`month_totals`, `month_rate_info`, `member_balances`,
// `daily_meal_totals`); the per-day grids below only arrange raw meal rows
// for display and never feed a bill.

import '../../../core/dates.dart';
import '../../meals/domain/meal.dart';
import '../../mess/domain/member.dart';
import '../../money/domain/money.dart';
import '../../month/domain/month.dart';

class ReportData {
  const ReportData({
    required this.messName,
    required this.period,
    required this.totals,
    required this.balances,
    required this.locale,
    required this.generatedOn,
    this.address,
    this.managerName,
    this.closed = false,
    this.members = const [],
    this.mealTypes = const [],
    this.entries = const [],
    this.dayTotals = const [],
    this.bazars = const [],
    this.expenses = const [],
    this.deposits = const [],
    this.categories = const {},
  });

  final String messName;
  final String? address;
  final String? managerName;
  final MonthPeriod period;
  final bool closed;

  /// SQL `month_totals` + `month_rate_info`.
  final MonthTotals totals;

  /// SQL `member_balances`; also decides who is in the report, in its order.
  final List<MemberBalance> balances;

  /// For join/leave dates.
  final List<Member> members;

  /// In display order (`sort_order`).
  final List<MealType> mealTypes;
  final List<MealEntry> entries;

  /// SQL `daily_meal_totals`.
  final List<DayMeals> dayTotals;

  /// Oldest first.
  final List<Bazar> bazars;
  final List<Expense> expenses;
  final List<Deposit> deposits;

  /// Expense category id → name.
  final Map<String, String> categories;

  /// 'bn' or 'en'. Bangla also switches the digits.
  final String locale;
  final DateTime generatedOn;

  bool get banglaDigits => locale.startsWith('bn');

  /// Every calendar day of the period.
  List<DateTime> get days => [
    for (
      var d = period.start;
      d.isBefore(period.end);
      d = DateTime(d.year, d.month, d.day + 1)
    )
      d,
  ];

  /// Enabled types plus any disabled type that still has rows this month.
  List<MealType> get shownTypes {
    final used = {for (final e in entries) e.mealTypeId};
    return [
      for (final t in mealTypes)
        if (t.enabled || used.contains(t.id)) t,
    ];
  }

  String nameOf(String? memberId) {
    for (final b in balances) {
      if (b.memberId == memberId) return b.displayName;
    }
    for (final m in members) {
      if (m.id == memberId) return m.displayName;
    }
    return '';
  }

  /// Member ids of a bazar's buyers, in display order.
  // TODO(bazar_buyers): return the bazar's `bazar_buyers` member ids here.
  List<String> buyerIdsOf(Bazar b) => [?b.buyerMemberId];

  /// SQL `is_present` (0004): not pending, joined_on <= d < left_on.
  /// Members missing from [members] count as present.
  bool present(String memberId, DateTime day) {
    final m = members.where((m) => m.id == memberId).firstOrNull;
    if (m == null) return true;
    return m.status != MemberStatus.pending &&
        !m.joinedOn.isAfter(day) &&
        (m.leftOn == null || day.isBefore(m.leftOn!));
  }

  /// People present on [day] (for "everyone (n)" on equal-split expenses).
  int presentCount(DateTime day) =>
      balances.where((b) => present(b.memberId, day)).length;
}

/// One member × day. [entries] is keyed by meal type id.
class ReportDay {
  const ReportDay({
    required this.present,
    required this.entries,
    required this.weighted,
  });

  final bool present;
  final Map<String, MealEntry> entries;

  /// Display-only: Σ (count + guests) × weight, like `member_meal_totals`.
  final double weighted;

  /// Rows exist and every one is off.
  bool get off => entries.isNotEmpty && entries.values.every((e) => e.isOff);

  /// Nothing to show: not in the mess and nothing recorded.
  bool get out => !present && entries.isEmpty;
}

/// A member's month for the grids and the meal-type table.
class ReportMember {
  const ReportMember({
    required this.balance,
    required this.days,
    required this.typeCounts,
    required this.guests,
    required this.offDays,
    required this.bazarTrips,
  });

  final MemberBalance balance;
  final List<ReportDay> days;

  /// Unweighted eaten meals per shown type (off rows count 0).
  final List<double> typeCounts;
  final int guests;
  final int offDays;
  final int bazarTrips;

  String get name => balance.displayName;
}

List<ReportMember> reportMembers(ReportData d) {
  final types = d.shownTypes;
  final weight = {for (final t in d.mealTypes) t.id: t.weight};
  final byKey = <(String, String), Map<String, MealEntry>>{};
  for (final e in d.entries) {
    (byKey[(e.memberId, isoDate(e.date))] ??= {})[e.mealTypeId] = e;
  }
  final days = d.days;
  return [
    for (final b in d.balances)
      () {
        final mine = [
          for (final day in days)
            () {
              final entries = byKey[(b.memberId, isoDate(day))] ?? const {};
              return ReportDay(
                present: d.present(b.memberId, day),
                entries: entries,
                weighted: entries.values.fold(
                  0.0,
                  (s, e) => s + e.people * (weight[e.mealTypeId] ?? 1),
                ),
              );
            }(),
        ];
        final all = [for (final x in mine) ...x.entries.values];
        return ReportMember(
          balance: b,
          days: mine,
          typeCounts: [
            for (final t in types)
              all
                  .where((e) => e.mealTypeId == t.id && !e.isOff)
                  .fold(0.0, (s, e) => s + e.count),
          ],
          guests: all.fold(0, (s, e) => s + e.guestCount),
          offDays: mine.where((x) => x.off).length,
          bazarTrips: d.bazars
              .where((z) => d.buyerIdsOf(z).contains(b.memberId))
              .length,
        );
      }(),
  ];
}
