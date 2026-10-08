import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/report/application/report_pdf.dart';

MemberBalance _b(String name, double closing) => MemberBalance(
  memberId: name,
  displayName: name,
  meals: 10.5,
  foodCost: 825.37,
  extraCost: 250,
  credit: 1500,
  openingBalance: 0,
  closingBalance: closing,
);

ReportData _data(List<MemberBalance> balances, {String locale = 'bn'}) =>
    ReportData(
      messName: 'রহমান মেস',
      period: MonthPeriod(DateTime(2026, 10), DateTime(2026, 11)),
      totals: const MonthTotals(
        foodTotal: 1410,
        totalMeals: 20.5,
        mealRate: 68.78,
        extraTotal: 500,
        creditTotal: 1500,
      ),
      balances: balances,
      locale: locale,
      generatedOn: DateTime(2026, 10, 8),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('HindSiliguri')
      ..addFont(rootBundle.load('assets/fonts/HindSiliguri-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/HindSiliguri-SemiBold.ttf'));
    await loader.load();
  });

  group('reportRows', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final bn = lookupAppLocalizations(const Locale('bn'));

    test('formats cells and marks due/advance', () {
      final rows = reportRows([
        _b('Rahim', 424.63),
        _b('Karim', -1234.5),
        _b('Zero', 0),
      ], l: en);
      expect(rows[0].cells, [
        'Rahim',
        '10½',
        '৳825.37',
        '৳250',
        '৳1,500',
        '৳424.63 advance',
      ]);
      expect(rows[0].due, isFalse);
      expect(rows[1].cells.last, '৳1,234.50 due');
      expect(rows[1].due, isTrue);
      expect(rows[2].cells.last, '৳0');
    });

    test('Bangla digits', () {
      final rows = reportRows([_b('রহিম', -50)], l: bn, banglaDigits: true);
      expect(rows.single.cells.sublist(1), [
        '১০½',
        '৳৮২৫.৩৭',
        '৳২৫০',
        '৳১,৫০০',
        '৳৫০ বাকি',
      ]);
    });

    test('empty', () => expect(reportRows([], l: en), isEmpty));
  });

  test('needsShaping: letters yes, digits and ৳ no', () {
    expect(needsShaping('রহিম'), isTrue);
    expect(needsShaping('৳১,৫০০'), isFalse);
    expect(needsShaping('Rahim 12'), isFalse);
  });

  group('buildMonthReportPdf', () {
    Future<Uint8List> build(int n, {String locale = 'bn'}) =>
        buildMonthReportPdf(
          _data([
            for (var i = 0; i < n; i++)
              _b(i.isEven ? 'সদস্য নম্বর $i' : 'Member $i', i - 20.0),
          ], locale: locale),
        );

    bool isPdf(Uint8List b) => String.fromCharCodes(b.take(5)) == '%PDF-';

    test('0 members', () async {
      final b = await build(0);
      expect(isPdf(b), isTrue);
    });

    test('40 members (bn) stays small', () async {
      final b = await build(40);
      expect(isPdf(b), isTrue);
      expect(b.length, lessThan(1024 * 1024));
    });

    test('40 members (en)', () async {
      final b = await build(40, locale: 'en');
      expect(isPdf(b), isTrue);
      expect(b.length, lessThan(1024 * 1024));
    });
  });
}
