import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/share_bills/domain/share_text.dart';

// The PRODUCT_RULES §3 worked example, as the SQL reports it.
const totals = MonthTotals(
  foodTotal: 1410,
  totalMeals: 20.5,
  mealRate: 68.780487804878,
  extraTotal: 500,
  creditTotal: 1500,
);

MemberBalance bal(
  String name,
  double closing, {
  double meals = 0,
  double food = 0,
  double extra = 0,
  double credit = 0,
  double opening = 0,
}) => MemberBalance(
  memberId: name,
  displayName: name,
  meals: meals,
  foodCost: food,
  extraCost: extra,
  credit: credit,
  openingBalance: opening,
  closingBalance: closing,
);

final rahim = bal(
  'Rahim',
  424.63,
  meals: 12,
  food: 825.37,
  extra: 250,
  credit: 1500,
);
final karim = bal('Karim', -834.63, meals: 8.5, food: 584.63, extra: 250);
final period = MonthPeriod(DateTime(2026, 10, 1), DateTime(2026, 11, 1));

void main() {
  group('memberBillText', () {
    test('advance, Bangla digits by default', () {
      final s = memberBillText(rahim, totals, mess: 'সবুজ মেস', period: period);
      expect(s, contains('*সবুজ মেস* · মাসের বিল'));
      expect(s, contains('১ অক্টোবর ২০২৬ – ৩১ অক্টোবর ২০২৬'));
      expect(s, contains('মিল: ১২ × ৳৬৮.৭৮ = ৳৮২৫.৩৭'));
      expect(s, contains('অন্যান্য খরচের ভাগ: ৳২৫০'));
      expect(s, contains('জমা দিয়েছেন: ৳১,৫০০'));
      expect(s, contains('*অগ্রিম: ৳৪২৪.৬৩*'));
      expect(s, isNot(contains('আগের মাস')), reason: 'zero opening hidden');
      expect(s, isNot(matches(RegExp('[0-9]'))));
    });

    test('due with opening balance, English digits', () {
      final s = memberBillText(
        bal('Karim', -834.63, meals: 8.5, food: 584.63, opening: -100),
        totals,
        mess: 'Green',
        period: period,
        locale: 'en',
      );
      expect(s, contains('Meals: 8½ × ৳68.78 = ৳584.63'));
      expect(s, contains('−৳100'));
      expect(s, endsWith('*Due: ৳834.63*'));
    });

    test('zero balance is settled, no amount', () {
      final s = memberBillText(bal('Z', 0), totals, mess: 'M', period: period);
      expect(s, endsWith('*মিটে গেছে*'));
    });

    test('banglaDigits can be overridden', () {
      final s = memberBillText(
        rahim,
        totals,
        mess: 'M',
        period: period,
        banglaDigits: false,
      );
      expect(s, contains('৳424.63'));
    });
  });

  test('messSummaryText: totals, dues first (largest first), settled last', () {
    final s = messSummaryText(
      [rahim, bal('Zero', 0), bal('Small', -10), karim],
      totals,
      mess: 'M',
      period: period,
      locale: 'en',
    );
    expect(s, contains('Total food cost: ৳1,410'));
    expect(s, contains('Total meals: 20½'));
    expect(s, contains('Meal rate: ৳68.78'));
    expect(s, isNot(contains('Fixed rate')));
    const fixed = MonthTotals(
      foodTotal: 1410,
      totalMeals: 20.5,
      mealRate: 60,
      extraTotal: 0,
      creditTotal: 0,
      fixedRate: true,
    );
    expect(
      messSummaryText([], fixed, mess: 'M', period: period),
      contains('মিল রেট: ৳৬০ (নির্দিষ্ট রেট)'),
    );
    expect(s, contains('Other expenses: ৳500'));
    final lines = s.split('\n').where((x) => x.startsWith('• ')).toList();
    expect(lines, [
      '• Karim: Due: ৳834.63',
      '• Small: Due: ৳10',
      '• Rahim: Advance: ৳424.63',
      '• Zero: Settled',
    ]);
  });

  group('dueReminderText', () {
    test('polite by default, Bangla amount, no payment line', () {
      final s = dueReminderText(karim);
      expect(s, startsWith('আসসালামু আলাইকুম Karim'));
      expect(s, contains('৳৮৩৪.৬৩'));
      expect(s, isNot(contains('বিকাশ')));
      expect(s.split('\n'), hasLength(1));
    });

    test('each tone has its own template', () {
      final texts = {
        for (final t in ReminderTone.values)
          t: dueReminderText(karim, tone: t, locale: 'en'),
      };
      expect(texts.values.toSet(), hasLength(3));
      expect(
        texts[ReminderTone.short],
        'Karim, mess due: ৳834.63. Please pay.',
      );
      expect(texts[ReminderTone.firm], contains('within 3 days'));
    });

    test('payment number adds a bKash/Nagad line', () {
      expect(
        dueReminderText(karim, paymentNumber: '01711000000'),
        endsWith('\nবিকাশ/নগদ: ০১৭১১০০০০০০'),
      );
      expect(
        dueReminderText(karim, paymentNumber: '  '),
        isNot(contains('\n')),
      );
    });
  });
}
