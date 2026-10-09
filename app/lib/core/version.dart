/// The app version, kept in step with `pubspec.yaml` (a test checks it).
const appVersion = '1.0.0';

/// Compares dotted versions numerically ("1.10.0" > "1.9.2"). A build
/// suffix (`+3`) and missing or non-numeric parts count as 0.
int compareVersions(String a, String b) {
  List<int> parts(String v) => [
    for (final p in v.split('+').first.trim().split('.'))
      int.tryParse(p.trim()) ?? 0,
  ];
  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    final c = (i < x.length ? x[i] : 0).compareTo(i < y.length ? y[i] : 0);
    if (c != 0) return c;
  }
  return 0;
}
