import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/format.dart';

void main() {
  group('Fmt.money', () {
    test('groups lakh style and keeps paise', () {
      expect(Fmt.money(123456.5), '৳1,23,456.50');
      expect(Fmt.money(12345678), '৳1,23,45,678');
      expect(Fmt.money(1000), '৳1,000');
      expect(Fmt.money(999), '৳999');
      expect(Fmt.money(0), '৳0');
    });

    test('negative and rounding-to-zero', () {
      expect(Fmt.money(-1410), '-৳1,410');
      expect(Fmt.money(-0.001), '৳0');
    });

    test('bangla digits', () {
      expect(Fmt.money(123456.5, banglaDigits: true), '৳১,২৩,৪৫৬.৫০');
    });
  });

  group('Fmt.meals', () {
    test('halves', () {
      expect(Fmt.meals(1), '1');
      expect(Fmt.meals(0.5), '½');
      expect(Fmt.meals(1.5), '1½');
      expect(Fmt.meals(0), '0');
      expect(Fmt.meals(20.5, banglaDigits: true), '২০½');
      expect(Fmt.meals(1.25), '1.25');
    });
  });

  group('Fmt.dateLong', () {
    final d = DateTime(2026, 10, 8);
    test('bn and en', () {
      expect(
        Fmt.dateLong(d, locale: 'bn', banglaDigits: true),
        '৮ অক্টোবর ২০২৬',
      );
      expect(Fmt.dateLong(d, locale: 'en'), '8 October 2026');
    });
  });
}
