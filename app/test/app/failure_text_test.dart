import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/failure_text.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('maps every failure kind to localized text', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('bn'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final l = AppLocalizations.of(ctx);
    String t(Object e) => failureText(ctx, e);

    expect(t(const AppFailure(FailureKind.network)), l.networkError);
    expect(t(const AppFailure(FailureKind.invalidOtp)), l.failureInvalidOtp);
    expect(t(const AppFailure(FailureKind.unknown)), l.genericError);
    expect(t(StateError('boom')), l.genericError);
    expect(
      t(const PostgrestException(message: 'INVALID_INVITE', code: 'P0001')),
      l.failureInvalidInvite,
    );
    // Every kind has its own non-empty text.
    final texts = {for (final k in FailureKind.values) t(AppFailure(k))};
    expect(texts.length, FailureKind.values.length);
  });
}
