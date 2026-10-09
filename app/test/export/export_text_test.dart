import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/dates.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/features/export/application/export_text.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/money/domain/money.dart';
import 'package:meal_bazar/features/month/domain/month.dart';

final l = lookupAppLocalizations(const Locale('bn'));

MealType _t(String id, String name, {bool enabled = true}) => MealType(
  id: id,
  messId: 'x',
  name: name,
  sortOrder: 0,
  weight: 1,
  enabled: enabled,
);

Member _m(String id, String name, [MemberStatus s = MemberStatus.active]) =>
    Member(
      id: id,
      messId: 'x',
      displayName: name,
      role: MemberRole.member,
      status: s,
      joinedOn: DateTime(2026),
    );

List<String> _lines(String csv) => csv.substring(1).split('\r\n')..removeLast();

void main() {
  group('toCsv', () {
    test('BOM, CRLF, RFC 4180 quoting, Latin decimals, ISO dates', () {
      final csv = toCsv([
        ['a,b', 'say "hi"', 'two\nlines', 'plain'],
        [12.5, 3.0, 0.25, -40, DateTime(2026, 10, 9), null],
      ]);
      expect(csv.startsWith('﻿'), isTrue);
      expect(
        csv,
        '﻿"a,b","say ""hi""","two\nlines",plain\r\n'
        '12.5,3,0.25,-40,2026-10-09,\r\n',
      );
    });

    test('Bangla text is kept; formula-like text is defused', () {
      final csv = toCsv([
        ['রহিম উদ্দিন', '=SUM(A1)', '@x', '-5 টাকা'],
      ]);
      expect(_lines(csv).single, "রহিম উদ্দিন,'=SUM(A1),'@x,'-5 টাকা");
    });
  });

  test('balancesCsv: header + SQL figures as plain numbers', () {
    final csv = balancesCsv(l, [
      const MemberBalance(
        memberId: 'a',
        displayName: 'করিম',
        meals: 42.5,
        foodCost: 2125.37,
        extraCost: 300,
        credit: 3000,
        openingBalance: -100,
        closingBalance: 474.63,
      ),
    ]);
    expect(_lines(csv), [
      'নাম,মিল,খাবার খরচ,অন্যান্য,জমা,আগের ব্যালেন্স,ব্যালেন্স',
      'করিম,42.5,2125.37,300,3000,-100,474.63',
    ]);
  });

  test('mealsCsv: one row per member per day, types + guests', () {
    final csv = mealsCsv(
      l,
      period: MonthPeriod(DateTime(2026, 10, 1), DateTime(2026, 10, 3)),
      members: [
        _m('a', 'আলম'),
        _m('b', 'বাবু'),
        _m('gone', 'Left, no meals', MemberStatus.left),
      ],
      mealTypes: [
        _t('d', 'দুপুর'),
        _t('r', 'রাত'),
        _t('s', 'সকাল', enabled: false),
      ],
      entries: [
        MealEntry(
          memberId: 'a',
          mealTypeId: 'd',
          date: DateTime(2026, 10, 1),
          guestCount: 2,
        ),
        MealEntry(
          memberId: 'a',
          mealTypeId: 'r',
          date: DateTime(2026, 10, 1),
          count: 0.5,
          guestCount: 1,
        ),
        MealEntry(
          memberId: 'b',
          mealTypeId: 'r',
          date: DateTime(2026, 10, 2),
          count: 0,
          isOff: true,
        ),
      ],
    );
    expect(_lines(csv), [
      'তারিখ,সদস্য,দুপুর,রাত,অতিথি',
      '2026-10-01,আলম,1,0.5,3',
      '2026-10-01,বাবু,0,0,0',
      '2026-10-02,আলম,0,0,0',
      '2026-10-02,বাবু,0,0,0',
    ]);
  });

  test('money CSVs resolve names, fund, items and labels', () {
    final names = {'a': 'আলম'};
    final bazar = bazarsCsv(l, [
      Bazar(
        id: '1',
        messId: 'x',
        date: DateTime(2026, 10, 5),
        amount: 650.5,
        buyers: ['a'],
        note: 'চাল, ডাল',
        items: const [
          BazarItem(id: 'i', name: 'চাল', price: 400, qty: 5, unit: 'kg'),
          BazarItem(id: 'j', name: 'ডিম', price: 250.5),
        ],
      ),
    ], names);
    expect(
      _lines(bazar)[1],
      '2026-10-05,650.5,আলম,মেস ফান্ড,চাল 5 kg 400; ডিম 250.5,"চাল, ডাল"',
    );

    final expense = expensesCsv(
      l,
      [
        Expense(
          id: '1',
          messId: 'x',
          date: DateTime(2026, 10, 6),
          categoryId: 'c',
          amount: 1200,
          split: SplitMethod.equal,
          paidByMemberId: 'a',
        ),
      ],
      {'c': 'গ্যাস'},
      names,
    );
    expect(_lines(expense)[1], '2026-10-06,গ্যাস,1200,সমান,আলম,');

    final deposit = depositsCsv(l, [
      Deposit(
        id: '1',
        messId: 'x',
        memberId: 'a',
        date: DateTime(2026, 10, 7),
        amount: 2000,
        method: PayMethod.bkash,
        trxId: 'ABC123',
        status: DepositStatus.pending,
      ),
    ], names);
    expect(_lines(deposit)[1], '2026-10-07,আলম,2000,বিকাশ,ABC123,যাচাই বাকি,');
  });

  group('cookMealCountText', () {
    final types = [
      _t('s', 'সকাল'),
      _t('d', 'দুপুর'),
      _t('r', 'রাত'),
      _t('x', 'নাশতা', enabled: false),
    ];
    final now = today();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    MealEntry e(
      String type, {
      double count = 1,
      int guests = 0,
      bool off = false,
    }) => MealEntry(
      memberId: 'm',
      mealTypeId: type,
      date: tomorrow,
      count: count,
      guestCount: guests,
      isOff: off,
    );

    test('tomorrow: heads per type incl. guests, off = 0, Bangla digits', () {
      final text = cookMealCountText(
        date: tomorrow,
        mealTypes: types,
        entries: [
          for (var i = 0; i < 8; i++) e('s'),
          for (var i = 0; i < 10; i++) e('d'),
          e('d', guests: 2),
          e('d', count: 0, off: true),
          for (var i = 0; i < 11; i++) e('r'),
          e('r', off: true, count: 0),
          e('x'),
        ],
        messName: 'সবুজ মেস',
        banglaDigits: true,
      );
      final lines = text.split('\n');
      expect(lines.first, 'সবুজ মেস');
      expect(lines.last, startsWith('কাল ('));
      expect(
        lines.last,
        endsWith(') মিল: সকাল ৮ · দুপুর ১৩ · রাত ১১ (অতিথি ২ সহ)'),
      );
    });

    test('a fixed date, Latin digits, no guests, no mess name', () {
      final text = cookMealCountText(
        date: DateTime(2020, 10, 10),
        mealTypes: types,
        entries: [
          MealEntry(
            memberId: 'm',
            mealTypeId: 'd',
            date: DateTime(2020, 10, 10),
            count: 0.5,
          ),
          MealEntry(
            memberId: 'm',
            mealTypeId: 'd',
            date: DateTime(2020, 10, 11),
          ),
        ],
        messName: '',
        banglaDigits: false,
      );
      expect(text, 'শনি 10 অক্টো মিল: সকাল 0 · দুপুর ½ · রাত 0');
    });
  });
}
