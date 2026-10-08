import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/ai/data/ai_client.dart';
import 'package:meal_bazar/features/ai/presentation/ai_entry.dart';
import 'package:meal_bazar/features/meals/application/meal_providers.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:mocktail/mocktail.dart';

class MockMeals extends Mock implements MealController {}

class FixedMess extends CurrentMessId {
  @override
  String? build() => 'mess1';
}

final l = lookupAppLocalizations(const Locale('bn'));
final day = DateTime(2026, 10, 8);

Member member(String id, String name) => Member(
  id: id,
  messId: 'mess1',
  displayName: name,
  role: MemberRole.member,
  status: MemberStatus.active,
  joinedOn: DateTime(2026, 10, 1),
);

Map<String, Object> entry(String member, {num count = 1, bool off = false}) => {
  'member_id': member,
  'meal_type_id': 'lunch',
  'count': count,
  'guest_count': 0,
  'is_off': off,
};

late MockMeals meals;

Future<void> open(WidgetTester tester, Object gatewayReply) async {
  meals = MockMeals();
  when(
    () => meals.save(any(), any(), source: any(named: 'source')),
  ).thenAnswer((_) async {});
  final ai = AiClient(
    MockClient(
      (_) async =>
          http.Response.bytes(utf8.encode(jsonEncode(gatewayReply)), 200),
    ),
    baseUrl: 'https://ai.example',
    token: () => 'jwt',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentMessIdProvider.overrideWith(FixedMess.new),
        aiClientProvider.overrideWithValue(ai),
        mealControllerProvider.overrideWithValue(meals),
        membersProvider.overrideWith(
          (ref, _) async => [member('r', 'রহিম'), member('k', 'করিম')],
        ),
        mealTypesProvider.overrideWith(
          (ref, _) async => [
            const MealType(
              id: 'lunch',
              messId: 'mess1',
              name: 'দুপুর',
              sortOrder: 0,
              weight: 1,
              enabled: true,
            ),
          ],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMealDraftSheet(context, day: day),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'আজ রহিম ১, করিম অফ');
  await tester.tap(find.text(l.aiSend));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(
    () => registerFallbackValue(
      MealEntry(memberId: '', mealTypeId: '', date: day),
    ),
  );

  final draft = {
    'draft': {
      'entries': [entry('r'), entry('k', count: 0, off: true)],
      'unmatched': ['রাতে গেস্ট ১ — কার?'],
      'confidence': 0.9,
    },
  };

  testWidgets('edit a row, remove another, Confirm All saves the rest as ai', (
    tester,
  ) async {
    await open(tester, draft);
    expect(find.text('রহিম · দুপুর · ১'), findsOneWidget);
    expect(find.text('করিম · দুপুর · ${l.mealCellOff}'), findsOneWidget);
    expect(find.text('রাতে গেস্ট ১ — কার?'), findsOneWidget);
    expect(find.text(l.aiDraftLabel), findsOneWidget);

    // Remove Karim.
    await tester.tap(find.byTooltip(l.aiRemove).at(1));
    await tester.pumpAndSettle();
    expect(find.textContaining('করিম'), findsNothing);

    // Edit Rahim to ½.
    await tester.tap(find.byTooltip(l.aiEdit));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '½'));
    await tester.tap(find.text(l.mealCellSave));
    await tester.pumpAndSettle();
    expect(find.text('রহিম · দুপুর · ½'), findsOneWidget);

    await tester.tap(find.text(l.aiConfirmAll));
    await tester.pumpAndSettle();

    final saved = verify(
      () => meals.save('mess1', captureAny(), source: 'ai'),
    ).captured.cast<MealEntry>();
    expect(saved, hasLength(1));
    expect((saved.single.memberId, saved.single.count), ('r', 0.5));
    expect(saved.single.date, day);
    expect(find.text(l.aiMealsSaved('১')), findsOneWidget);
  });

  testWidgets('Reject saves nothing', (tester) async {
    await open(tester, draft);
    await tester.tap(find.text(l.aiReject));
    await tester.pumpAndSettle();
    verifyNever(() => meals.save(any(), any(), source: any(named: 'source')));
    expect(find.text(l.aiConfirmAll), findsNothing);
  });

  testWidgets('quota shows a calm message and saves nothing', (tester) async {
    await open(tester, {'unavailable': true, 'reason': 'quota'});
    expect(find.text(l.aiUnavailableQuota), findsOneWidget);
    expect(find.text(l.aiConfirmAll), findsNothing);
    verifyNever(() => meals.save(any(), any(), source: any(named: 'source')));
  });
}
