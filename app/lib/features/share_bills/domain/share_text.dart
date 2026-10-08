import 'dart:ui' show Locale;

import '../../../core/format.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../month/domain/month.dart';

// WhatsApp-friendly bill texts. Pure: every figure comes from the SQL read
// models and is only formatted here, never recomputed.

enum ReminderTone { polite, short, firm }

/// One member's bill: meals × rate = food, extra share, paid, balance.
String memberBillText(
  MemberBalance b,
  MonthTotals t, {
  required String mess,
  required MonthPeriod period,
  String locale = 'bn',
  bool? banglaDigits,
}) {
  final f = _Fmt(locale, banglaDigits);
  final l = f.l;
  return [
    l.shareBillTitle(mess),
    f.period(period),
    '',
    '*${b.displayName}*',
    l.shareBillMeals(
      f.meals(b.meals),
      f.money(t.mealRate),
      f.money(b.foodCost),
    ),
    '${l.balanceExtra}: ${f.money(b.extraCost)}',
    if (b.openingBalance != 0)
      '${l.balanceOpening}: ${f.signed(b.openingBalance)}',
    '${l.shareBillPaid}: ${f.money(b.credit)}',
    '',
    '*${f.balance(b.closingBalance)}*',
  ].join('\n');
}

/// The whole mess: month totals, then one line per member, dues first
/// (largest due on top), then advances, then settled.
String messSummaryText(
  List<MemberBalance> balances,
  MonthTotals t, {
  required String mess,
  required MonthPeriod period,
  String locale = 'bn',
  bool? banglaDigits,
}) {
  final f = _Fmt(locale, banglaDigits);
  final l = f.l;
  // Dues ascending (most negative first), then advances, settled last.
  int rank(double v) => v < 0 ? 0 : (v > 0 ? 1 : 2);
  final sorted = [...balances]
    ..sort((a, b) {
      final r = rank(a.closingBalance).compareTo(rank(b.closingBalance));
      return r != 0 ? r : a.closingBalance.compareTo(b.closingBalance);
    });
  return [
    l.shareBillSummaryTitle(mess),
    f.period(period),
    '',
    '${l.shareBillFoodTotal}: ${f.money(t.foodTotal)}',
    '${l.shareBillTotalMeals}: ${f.meals(t.totalMeals)}',
    '${l.shareBillRate}: ${f.money(t.mealRate)}'
        '${t.fixedRate ? ' (${l.rateFixed})' : ''}',
    if (t.extraTotal != 0) '${l.shareBillExtraTotal}: ${f.money(t.extraTotal)}',
    '',
    for (final b in sorted)
      '• ${b.displayName}: ${f.balance(b.closingBalance)}',
  ].join('\n');
}

/// A due reminder from a template. Meant for members with a due
/// (negative balance); the amount shown is the due's absolute value.
/// [paymentNumber] adds a bKash/Nagad line; omitted when not configured.
String dueReminderText(
  MemberBalance b, {
  ReminderTone tone = ReminderTone.polite,
  String locale = 'bn',
  bool? banglaDigits,
  String? paymentNumber,
}) {
  final f = _Fmt(locale, banglaDigits);
  final l = f.l;
  final amount = f.money(b.closingBalance.abs());
  final body = switch (tone) {
    ReminderTone.polite => l.shareBillRemindPolite(b.displayName, amount),
    ReminderTone.short => l.shareBillRemindShort(b.displayName, amount),
    ReminderTone.firm => l.shareBillRemindFirm(b.displayName, amount),
  };
  final number = paymentNumber?.trim();
  return [
    body,
    if (number != null && number.isNotEmpty)
      l.shareBillPayHint(f.digits(number)),
  ].join('\n');
}

String reminderToneLabel(AppLocalizations l, ReminderTone t) => switch (t) {
  ReminderTone.polite => l.shareBillTonePolite,
  ReminderTone.short => l.shareBillToneShort,
  ReminderTone.firm => l.shareBillToneFirm,
};

class _Fmt {
  _Fmt(this.locale, bool? banglaDigits)
    : l = lookupAppLocalizations(Locale(locale)),
      bn = banglaDigits ?? locale == 'bn';

  final String locale;
  final AppLocalizations l;
  final bool bn;

  String money(num v) => Fmt.money(v, banglaDigits: bn);
  String signed(num v) => '${v < 0 ? '−' : '+'}${money(v.abs())}';
  String meals(num v) => Fmt.meals(v, banglaDigits: bn);
  String digits(String s) => Fmt.digits(s, bangla: bn);

  String period(MonthPeriod p) => l.dashPeriod(
    Fmt.dateLong(p.start, locale: locale, banglaDigits: bn),
    // `end` is exclusive; show the last day of the period.
    Fmt.dateLong(
      DateTime(p.end.year, p.end.month, p.end.day - 1),
      locale: locale,
      banglaDigits: bn,
    ),
  );

  /// "বাকি: ৳500" / "অগ্রিম: ৳424.63" / "মিটে গেছে".
  String balance(double v) => v == 0
      ? l.balanceSettled
      : '${v < 0 ? l.balanceDue : l.balanceAdvance}: ${money(v.abs())}';
}
