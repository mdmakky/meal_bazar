import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/features/auth/domain/phone.dart';

void main() {
  test('accepts common BD formats', () {
    for (final input in [
      '01712345678',
      '1712345678',
      '+8801712345678',
      '8801712345678',
      '017-1234-5678',
      ' +880 1712 345678 ',
      '০১৭১২৩৪৫৬৭৮',
    ]) {
      expect(normalizeBdPhone(input), '+8801712345678', reason: input);
    }
  });

  test('accepts every operator prefix 013–019', () {
    for (var p = 3; p <= 9; p++) {
      expect(normalizeBdPhone('01${p}12345678'), '+8801${p}12345678');
    }
  });

  test('rejects invalid numbers', () {
    for (final input in [
      '',
      '01212345678', // 012 is not a mobile operator
      '01112345678',
      '0171234567', // too short
      '017123456789', // too long
      '0171234abcd',
      'abcdefghijk',
      '+01712345678', // + without country code
      '+9101712345678',
    ]) {
      expect(normalizeBdPhone(input), isNull, reason: input);
    }
  });
}
