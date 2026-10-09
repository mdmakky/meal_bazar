import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// supabase-dart sorts DESCENDING unless `ascending:` is given, which has
/// bitten us twice (meal type columns, chat order). Every `.order(` call in
/// lib/ must say its direction.
void main() {
  test('every Supabase .order() states ascending explicitly', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('.order(')) continue;
        // The call may wrap: look at this line and the next two.
        final call = lines.skip(i).take(3).join(' ');
        if (!call.contains('ascending:')) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
