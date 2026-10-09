import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/money/domain/money.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/report/application/report_pdf.dart';

final _oct = MonthPeriod(DateTime(2026, 10), DateTime(2026, 11));

MealType _type(String id, String name, int order, double w) => MealType(
  id: id,
  messId: 'x',
  name: name,
  sortOrder: order,
  weight: w,
  enabled: true,
);

final _types = [
  _type('b', 'সকাল', 0, 0.5),
  _type('l', 'দুপুর', 1, 1),
  _type('d', 'রাত', 2, 1),
];

Member _member(String id, String name, {int joined = 1, int? left}) => Member(
  id: id,
  messId: 'x',
  displayName: name,
  role: id == 'm0' ? MemberRole.manager : MemberRole.member,
  status: left == null ? MemberStatus.active : MemberStatus.left,
  joinedOn: DateTime(2026, joined < 1 ? 9 : 10, joined < 1 ? 1 : joined),
  leftOn: left == null ? null : DateTime(2026, 10, left),
);

MemberBalance _balance(Member m, double closing) => MemberBalance(
  memberId: m.id,
  displayName: m.displayName,
  meals: 62.5,
  foodCost: 4125.37,
  extraCost: 2250,
  credit: 6000,
  openingBalance: 335.48,
  closingBalance: closing,
);

const _items = [
  ('চাল', 'কেজি'),
  ('মসুর ডাল', 'কেজি'),
  ('সয়াবিন তেল', 'লি.'),
  ('আলু', 'কেজি'),
  ('পেঁয়াজ', 'কেজি'),
  ('রসুন', 'কেজি'),
  ('ডিম', 'হালি'),
  ('মুরগি', 'কেজি'),
  ('রুই মাছ', 'কেজি'),
  ('সবজি', 'কেজি'),
  ('কাঁচা মরিচ', 'কেজি'),
  ('গরুর মাংস', 'কেজি'),
  ('আটা', 'কেজি'),
  ('হলুদ', 'প্যাকেট'),
  ('Detergent powder family size', null),
];

Bazar _bazar(int day, String buyer, int items, {String? pocket}) => Bazar(
  id: 'bz$day',
  messId: 'x',
  date: DateTime(2026, 10, day),
  amount: 1000.0 + day,
  buyers: [buyer],
  paidByMemberId: pocket,
  items: [
    for (var i = 0; i < items; i++)
      BazarItem(
        id: 'i$day$i',
        name: _items[i].$1,
        unit: _items[i].$2,
        qty: i.isEven ? 1.5 : 2,
        price: 60.0 + i,
      ),
  ],
);

/// Full meals every present day, plus the special cases the grids show.
List<MealEntry> _entries(List<Member> members) => [
  for (final m in members)
    for (var day = 1; day <= 31; day++)
      for (final t in _types)
        if (!DateTime(2026, 10, day).isBefore(m.joinedOn) &&
            (m.leftOn == null || DateTime(2026, 10, day).isBefore(m.leftOn!)))
          MealEntry(
            memberId: m.id,
            mealTypeId: t.id,
            date: DateTime(2026, 10, day),
            // m0: half lunch on the 3rd, double dinner on the 10th.
            count: m.id == 'm1' && day == 7
                ? 0
                : m.id == 'm0' && day == 3 && t.id == 'l'
                ? 0.5
                : m.id == 'm0' && day == 10 && t.id == 'd'
                ? 2
                : 1,
            // m1: a guest at dinner on the 5th, all off on the 7th.
            guestCount: m.id == 'm1' && day == 5 && t.id == 'd' ? 1 : 0,
            isOff: m.id == 'm1' && day == 7,
          ),
];

ReportData _fixture({int extraMembers = 0, String locale = 'bn'}) {
  final members = [
    _member('m0', 'রাকিব হাসান'),
    _member('m1', 'তানভীর'),
    _member('m2', 'আরিফ', joined: 15),
    _member('m3', 'Jubayer Ahmed Chowdhury', joined: 0, left: 20),
    for (var i = 0; i < extraMembers; i++) _member('x$i', 'সদস্য নম্বর $i'),
  ];
  return ReportData(
    messName: 'শান্তিনীড় ছাত্রাবাস',
    address: 'বাড়ি ১২, রোড ৫, মিরপুর-১০',
    managerName: 'রাকিব হাসান',
    period: _oct,
    closed: true,
    totals: const MonthTotals(
      foodTotal: 15420,
      totalMeals: 310.5,
      mealRate: 49.66,
      extraTotal: 29000,
      creditTotal: 21000,
    ),
    balances: [
      for (final (i, m) in members.indexed) _balance(m, i.isEven ? 1250 : -840),
    ],
    members: members,
    mealTypes: _types,
    entries: _entries(members),
    dayTotals: [
      for (var day = 1; day <= 31; day++)
        (date: DateTime(2026, 10, day), meals: 10.5),
    ],
    bazars: [
      _bazar(2, 'm0', 6),
      _bazar(9, 'm1', 15, pocket: 'm1'),
      _bazar(16, 'm2', 4),
    ],
    expenses: [
      Expense(
        id: 'e1',
        messId: 'x',
        date: DateTime(2026, 10, 1),
        categoryId: 'rent',
        amount: 21000,
        split: SplitMethod.equal,
      ),
      Expense(
        id: 'e2',
        messId: 'x',
        date: DateTime(2026, 10, 20),
        categoryId: 'repair',
        amount: 1500,
        split: SplitMethod.equal,
        note: 'ফ্যান মেরামত',
        paidByMemberId: 'm0',
        shares: const {'m0': 1, 'm1': 2},
      ),
    ],
    deposits: [
      Deposit(
        id: 'd1',
        messId: 'x',
        memberId: 'm0',
        date: DateTime(2026, 10, 1),
        amount: 6000,
        method: PayMethod.bkash,
        trxId: 'BK7Q2XZ',
      ),
      Deposit(
        id: 'd2',
        messId: 'x',
        memberId: 'm1',
        date: DateTime(2026, 10, 14),
        amount: 3000,
        status: DepositStatus.pending,
      ),
      Deposit(
        id: 'd3',
        messId: 'x',
        memberId: 'm1',
        date: DateTime(2026, 10, 15),
        amount: 99,
        status: DepositStatus.rejected,
      ),
    ],
    categories: const {'rent': 'বাসা ভাড়া', 'repair': 'মেরামত'},
    locale: locale,
    generatedOn: DateTime(2026, 11, 2),
  );
}

ReportData _empty() => ReportData(
  messName: 'Empty mess',
  period: MonthPeriod(DateTime(2026, 2), DateTime(2026, 3)),
  totals: const MonthTotals(
    foodTotal: 0,
    totalMeals: 0,
    mealRate: 0,
    extraTotal: 0,
    creditTotal: 0,
  ),
  balances: const [],
  locale: 'bn',
  generatedOn: DateTime(2026, 3, 1),
);

/// Saves [d] and returns its pages as (width, height).
Future<List<(double, double)>> _pages(ReportData d, {String? out}) async {
  final doc = await buildMonthReport(d);
  final bytes = await doc.save();
  expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  if (out != null) File(out).writeAsBytesSync(bytes);
  return [
    for (final p in doc.document.pdfPageList.pages)
      (p.pageFormat.width, p.pageFormat.height),
  ];
}

bool _landscape((double, double) p) => p.$1 > p.$2;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('HindSiliguri')
      ..addFont(rootBundle.load('assets/fonts/HindSiliguri-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/HindSiliguri-SemiBold.ttf'));
    await loader.load();
  });

  test('needsShaping: letters yes, digits and ৳ no', () {
    expect(needsShaping('রহিম'), isTrue);
    expect(needsShaping('৳১,৫০০'), isFalse);
    expect(needsShaping('Rahim 12'), isFalse);
  });

  test('grid model: half, double, guest, off, joined and left', () {
    final d = _fixture();
    expect(d.days, hasLength(31));
    final [rakib, tanvir, arif, jubayer] = reportMembers(d);

    // Half lunch on the 3rd: ½×0.5 + 0.5 + 1 = 2.
    expect(rakib.days[2].weighted, 2);
    expect(rakib.days[2].entries['l']!.count, 0.5);
    expect(rakib.days[9].entries['d']!.count, 2);
    expect(rakib.typeCounts, [31, 30.5, 32]);
    expect(rakib.bazarTrips, 1);

    expect(tanvir.days[4].weighted, 3.5); // guest at dinner
    expect(tanvir.guests, 1);
    expect(tanvir.days[6].off, isTrue);
    expect(tanvir.offDays, 1);
    expect(tanvir.typeCounts, [30, 30, 30]);

    expect(arif.days[13].out, isTrue); // joined on the 15th
    expect(arif.days[14].out, isFalse);
    expect(jubayer.days[18].out, isFalse);
    expect(jubayer.days[19].out, isTrue); // left on the 20th

    expect(d.presentCount(DateTime(2026, 10, 1)), 3);
    expect(d.presentCount(DateTime(2026, 10, 16)), 4);
    expect(d.buyerIdsOf(d.bazars[1]), ['m1']);
  });

  test('fixture month: four sections, day grids on landscape', () async {
    final pages = await _pages(
      _fixture(),
      out: Platform.environment['REPORT_PDF_OUT'],
    );
    expect(pages, hasLength(4));
    expect(pages.take(2).every(_landscape), isTrue);
    expect(pages.skip(2).any(_landscape), isFalse);
  });

  test('31 days × 10 members × 15-item bazar fits without overflow', () async {
    // MultiPage throws when a block that must not split exceeds a page.
    final pages = await _pages(_fixture(extraMembers: 6));
    expect(pages.length, greaterThanOrEqualTo(4));
    expect(pages.where(_landscape).length, greaterThanOrEqualTo(2));
  });

  test('English locale', () async {
    expect(await _pages(_fixture(locale: 'en')), hasLength(4));
  });

  test('empty month does not throw', () async {
    final pages = await _pages(_empty());
    expect(pages, hasLength(4));
  });

  test('40 members paginate the day grids', () async {
    final pages = await _pages(_fixture(extraMembers: 36));
    expect(pages.where(_landscape).length, greaterThan(2));
  });
}
