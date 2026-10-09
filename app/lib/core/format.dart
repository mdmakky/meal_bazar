/// Display formatting. Pure functions; callers pass the user's digit setting.
abstract final class Fmt {
  static const _bnMonths = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];
  static const _enMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Replaces ASCII digits with Bangla digits (০-৯) when [bangla] is true.
  static String digits(String s, {required bool bangla}) {
    if (!bangla) return s;
    return String.fromCharCodes(
      s.codeUnits.map((c) => c >= 0x30 && c <= 0x39 ? c - 0x30 + 0x09E6 : c),
    );
  }

  /// ৳ with South Asian grouping (৳1,23,456.50); whole amounts drop `.00`.
  static String money(num amount, {bool banglaDigits = false}) {
    final fixed = amount.abs().toStringAsFixed(2);
    final [whole, paise] = fixed.split('.');
    final negative = amount < 0 && fixed != '0.00';
    final body = paise == '00' ? _group(whole) : '${_group(whole)}.$paise';
    return digits('${negative ? '-' : ''}৳$body', bangla: banglaDigits);
  }

  static String _group(String n) {
    if (n.length <= 3) return n;
    final head = n.substring(0, n.length - 3);
    final pairs = <String>[];
    for (var end = head.length; end > 0; end -= 2) {
      pairs.insert(0, head.substring(end - 2 < 0 ? 0 : end - 2, end));
    }
    return '${pairs.join(',')},${n.substring(n.length - 3)}';
  }

  /// Meal count, the one format everywhere: whole numbers plain (16),
  /// quarters as fractions (16¼, ½, 19½, 2¾); anything finer falls back to
  /// trimmed decimals (0.33).
  static String meals(num count, {bool banglaDigits = false}) {
    final quarters = count * 4;
    final String s;
    if ((quarters - quarters.round()).abs() < 1e-9) {
      final q = quarters.round();
      final whole = q.abs() ~/ 4;
      final frac = const ['', '¼', '½', '¾'][q.abs() % 4];
      final sign = q < 0 ? '-' : '';
      s = frac.isEmpty ? '$sign$whole' : '$sign${whole == 0 ? '' : whole}$frac';
    } else {
      s = count.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return digits(s, bangla: banglaDigits);
  }

  /// Long date: `৮ অক্টোবর ২০২৬` (bn) or `8 October 2026` (en).
  static String dateLong(
    DateTime d, {
    required String locale,
    bool banglaDigits = false,
  }) {
    final months = locale.startsWith('bn') ? _bnMonths : _enMonths;
    return digits(
      '${d.day} ${months[d.month - 1]} ${d.year}',
      bangla: banglaDigits,
    );
  }
}
