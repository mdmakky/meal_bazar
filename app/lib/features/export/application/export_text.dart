// Pure text builders for export and sharing. Figures come from SQL (balances)
// or are raw rows (meals, money); nothing here recomputes a bill.

import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../meals/domain/meal.dart';
import '../../mess/domain/member.dart';
import '../../money/domain/money.dart';
import '../../money/presentation/money_sheets.dart'
    show methodLabel, splitLabel;
import '../../month/domain/month.dart';

/// RFC 4180 CSV with a UTF-8 BOM so Excel reads Bangla correctly.
/// Cells: [num] → plain Latin decimal, [DateTime] → ISO date, else text.
String toCsv(List<List<Object?>> rows) =>
    '﻿${rows.map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n';

String _cell(Object? v) {
  var s = switch (v) {
    null => '',
    num n => _num(n),
    DateTime d => isoDate(d),
    _ => v.toString(),
  };
  // Text a spreadsheet would run as a formula (CSV injection) is kept as text.
  if (v is! num && s.startsWith(RegExp(r'[=+\-@\t\r]'))) s = "'$s";
  return s.contains(RegExp(r'[",\r\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
}

/// 12.5, 3, 0.25: at most 2 decimals, trailing zeros trimmed.
String _num(num v) => v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

/// The SQL `member_balances` rows as they are.
String balancesCsv(AppLocalizations l, List<MemberBalance> balances) => toCsv([
  [
    l.reportName,
    l.reportMeals,
    l.reportFoodCost,
    l.reportExtra,
    l.reportPaid,
    l.exportOpening,
    l.reportBalance,
  ],
  for (final b in balances)
    [
      b.displayName,
      b.meals,
      b.foodCost,
      b.extraCost,
      b.credit,
      b.openingBalance,
      b.closingBalance,
    ],
]);

/// One row per member per day of [period]: each meal type's count (off = 0)
/// and the day's guests. Members: active ones plus anyone with an entry.
/// Types: enabled ones plus any with an entry.
String mealsCsv(
  AppLocalizations l, {
  required MonthPeriod period,
  required List<Member> members,
  required List<MealType> mealTypes,
  required List<MealEntry> entries,
}) {
  final byKey = {
    for (final e in entries) (e.memberId, isoDate(e.date), e.mealTypeId): e,
  };
  final usedTypes = {for (final e in entries) e.mealTypeId};
  final usedMembers = {for (final e in entries) e.memberId};
  final types = [
    for (final t in mealTypes)
      if (t.enabled || usedTypes.contains(t.id)) t,
  ];
  final rows = [
    for (final m in members)
      if (m.status == MemberStatus.active || usedMembers.contains(m.id)) m,
  ];
  return toCsv([
    [
      l.exportDate,
      l.exportMember,
      for (final t in types) t.name,
      l.exportGuests,
    ],
    for (
      var d = period.start;
      d.isBefore(period.end);
      d = DateTime(d.year, d.month, d.day + 1)
    )
      for (final m in rows)
        _mealRow(d, m, [
          for (final t in types) byKey[(m.id, isoDate(d), t.id)],
        ]),
  ]);
}

List<Object?> _mealRow(DateTime d, Member m, List<MealEntry?> day) => [
  d,
  m.displayName,
  for (final e in day) e == null || e.isOff ? 0 : e.count,
  day.fold<int>(0, (n, e) => n + (e?.guestCount ?? 0)),
];

String bazarsCsv(
  AppLocalizations l,
  List<Bazar> bazars,
  Map<String, String> names,
) => toCsv([
  [
    l.exportDate,
    l.exportAmount,
    l.exportBuyer,
    l.exportPaidBy,
    l.exportItems,
    l.exportNote,
  ],
  for (final b in bazars)
    [
      b.date,
      b.amount,
      b.buyerNames(names) ?? '',
      _paidBy(l, names, b.paidByMemberId),
      b.items
          .map(
            (i) => [
              i.name,
              if (i.qty != null) _num(i.qty!),
              ?i.unit,
              _num(i.price),
            ].join(' '),
          )
          .join('; '),
      b.note,
    ],
]);

String expensesCsv(
  AppLocalizations l,
  List<Expense> expenses,
  Map<String, String> categories,
  Map<String, String> names,
) => toCsv([
  [
    l.exportDate,
    l.exportCategory,
    l.exportAmount,
    l.exportSplit,
    l.exportPaidBy,
    l.exportNote,
  ],
  for (final e in expenses)
    [
      e.date,
      categories[e.categoryId] ?? '',
      e.amount,
      splitLabel(l, e.split),
      _paidBy(l, names, e.paidByMemberId),
      e.note,
    ],
]);

String depositsCsv(
  AppLocalizations l,
  List<Deposit> deposits,
  Map<String, String> names,
) => toCsv([
  [
    l.exportDate,
    l.exportMember,
    l.exportAmount,
    l.exportMethod,
    'TrxID',
    l.exportStatus,
    l.exportNote,
  ],
  for (final d in deposits)
    [
      d.date,
      names[d.memberId] ?? '',
      d.amount,
      methodLabel(l, d.method),
      d.trxId,
      switch (d.status) {
        _ when d.isWithdrawal => l.withdrawTag,
        DepositStatus.verified => l.exportVerified,
        DepositStatus.pending => l.depositPending,
        DepositStatus.rejected => l.depositRejected,
      },
      d.note,
    ],
]);

String _paidBy(AppLocalizations l, Map<String, String> names, String? id) =>
    id == null ? l.moneyPaidFund : names[id] ?? '';

const _bnWeekdays = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহস্পতি', 'শুক্র', 'শনি', 'রবি'];
const _bnMonths = [
  'জানু',
  'ফেব্রু',
  'মার্চ',
  'এপ্রি',
  'মে',
  'জুন',
  'জুলাই',
  'আগ',
  'সেপ্টে',
  'অক্টো',
  'নভে',
  'ডিসে',
];

/// The cook's message, in Bangla (the cook's language, whatever the UI's):
/// "কাল (শনি ১০ অক্টো) মিল: সকাল ৮ · দুপুর ১২ · রাত ১১ (অতিথি ২ সহ)".
/// Counts are heads to cook for (count + guests, off = 0), not weighted meals.
String cookMealCountText({
  required DateTime date,
  required List<MealType> mealTypes,
  required List<MealEntry> entries,
  required String messName,
  required bool banglaDigits,
}) {
  String n(num v) => Fmt.meals(v, banglaDigits: banglaDigits);
  final day = dayOnly(date);
  final dayLabel =
      '${_bnWeekdays[day.weekday - 1]} ${n(day.day)} ${_bnMonths[day.month - 1]}';
  final now = today();
  final when = day == now
      ? 'আজ ($dayLabel)'
      : day == DateTime(now.year, now.month, now.day + 1)
      ? 'কাল ($dayLabel)'
      : dayLabel;
  final onDay = [
    for (final e in entries)
      if (dayOnly(e.date) == day) e,
  ];
  final counts = [
    for (final t in mealTypes)
      if (t.enabled)
        '${t.name} ${n(onDay.where((e) => e.mealTypeId == t.id).fold<double>(0, (s, e) => s + e.people))}',
  ];
  final guests = onDay
      .where((e) => mealTypes.any((t) => t.enabled && t.id == e.mealTypeId))
      .fold<int>(0, (s, e) => s + e.guestCount);
  final line =
      '$when মিল: ${counts.join(' · ')}${guests > 0 ? ' (অতিথি ${n(guests)} সহ)' : ''}';
  return messName.isEmpty ? line : '$messName\n$line';
}
