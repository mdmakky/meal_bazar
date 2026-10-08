const _banglaDigits = '০১২৩৪৫৬৭৮৯';

/// Normalises a Bangladeshi mobile number to E.164 (`+8801XXXXXXXXX`).
///
/// Accepts `01712345678`, `1712345678`, `8801712345678`, `+8801712345678`,
/// with spaces/dashes/brackets and Bangla digits. Operators 013–019 only.
/// Returns null when the input is not a valid BD mobile number.
String? normalizeBdPhone(String input) {
  var s = input.replaceAll(RegExp(r'[\s\-().]'), '');
  s = s.replaceAllMapped(
    RegExp('[$_banglaDigits]'),
    (m) => '${_banglaDigits.indexOf(m[0]!)}',
  );
  final hasPlus = s.startsWith('+');
  if (hasPlus) s = s.substring(1);
  if (s.startsWith('880')) {
    s = s.substring(3);
  } else if (hasPlus) {
    return null;
  }
  if (s.startsWith('0')) s = s.substring(1);
  return RegExp(r'^1[3-9]\d{8}$').hasMatch(s) ? '+880$s' : null;
}
