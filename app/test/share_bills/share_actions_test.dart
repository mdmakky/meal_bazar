import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/share_bills/presentation/share_bill_actions.dart';

import 'share_text_test.dart' show bal, karim, period, rahim, totals;

class _FixedMess extends CurrentMessId {
  @override
  String? build() => 'm1';
}

final l = lookupAppLocalizations(const Locale('bn'));
const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

Future<List<String>> pump(WidgetTester tester, MemberBalance b) async {
  final shared = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(shareChannel, (
    call,
  ) async {
    shared.add((call.arguments as Map)['text'] as String);
    return 'dev.fluttercommunity.plus/share/unavailable';
  });
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      shareChannel,
      null,
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentMessIdProvider.overrideWith(_FixedMess.new),
        monthTotalsProvider.overrideWith((ref, id) async => totals),
        currentPeriodProvider.overrideWith((ref, id) async => period),
        memberBalancesProvider.overrideWith((ref, id) async => [rahim, karim]),
      ],
      child: MaterialApp(
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              MemberShareActions(balance: b),
              const ShareMessSummaryButton(messId: 'm1'),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return shared;
}

void main() {
  testWidgets('remind → tone picker → shares that tone', (tester) async {
    final shared = await pump(tester, karim);

    await tester.tap(find.text(l.shareBillRemind));
    await tester.pumpAndSettle();
    expect(find.text(l.shareBillToneTitle), findsOneWidget);
    expect(find.text(l.shareBillTonePolite), findsOneWidget);
    expect(find.text(l.shareBillToneShort), findsOneWidget);
    expect(find.text(l.shareBillToneFirm), findsOneWidget);

    await tester.tap(find.text(l.shareBillToneShort));
    await tester.pumpAndSettle();
    expect(find.text(l.shareBillToneTitle), findsNothing);
    expect(shared, ['Karim, মেসের বাকি ৳৮৩৪.৬৩। দয়া করে দিয়ে দিন।']);
  });

  testWidgets('dismissing the picker shares nothing', (tester) async {
    final shared = await pump(tester, karim);
    await tester.tap(find.text(l.shareBillRemind));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(shared, isEmpty);
  });

  testWidgets('no remind for advance/settled; bill and summary share', (
    tester,
  ) async {
    final shared = await pump(tester, bal('Zero', 0));
    expect(find.text(l.shareBillRemind), findsNothing);

    await tester.tap(find.text(l.shareBillShare));
    await tester.tap(find.text(l.shareBillShareAll));
    await tester.pumpAndSettle();
    expect(shared, hasLength(2));
    expect(shared.first, contains('*মিটে গেছে*'));
    expect(
      shared.last.indexOf('Karim'),
      lessThan(shared.last.indexOf('Rahim')),
    );
  });
}
