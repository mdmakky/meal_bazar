import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/meals/application/meal_providers.dart';
import 'package:meal_bazar/features/meals/data/meal_repository.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/meals/presentation/meal_types_screen.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:mocktail/mocktail.dart';

class MockMealRepository extends Mock implements MealRepository {}

MealType type(String id, String name, int order, double w, bool on) => MealType(
  id: id,
  messId: 'mess1',
  name: name,
  sortOrder: order,
  weight: w,
  enabled: on,
);

void main() {
  late MockMealRepository repo;
  setUp(() {
    repo = MockMealRepository();
    when(() => repo.mealTypes(any())).thenAnswer(
      (_) async => [
        type('b', 'সকাল', 0, 0.5, false),
        type('l', 'দুপুর', 1, 1, true),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealRepositoryProvider.overrideWithValue(repo),
          myMembershipsProvider.overrideWith(
            (ref) async => [
              Membership(
                member: Member(
                  id: 'me',
                  messId: 'mess1',
                  displayName: 'Rahim',
                  role: MemberRole.manager,
                  status: MemberStatus.active,
                  joinedOn: DateTime(2026),
                ),
                mess: const Mess(
                  id: 'mess1',
                  name: 'Mess',
                  monthStartDay: 1,
                  currency: '৳',
                  mealOffCutoff: '22:00:00',
                ),
              ),
            ],
          ),
          amIManagerProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MealTypesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists types with weights and toggles enabled', (tester) async {
    when(
      () => repo.updateMealType(any(), enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    await pump(tester);

    expect(find.text('সকাল'), findsOneWidget);
    expect(find.text('দুপুর'), findsOneWidget);
    expect(find.text('×০.৫'), findsOneWidget);
    expect(find.text('×১'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    verify(() => repo.updateMealType('b', enabled: true)).called(1);
  });

  testWidgets('weight steps by a quarter', (tester) async {
    final saving = Completer<void>();
    when(
      () => repo.updateMealType(any(), weight: any(named: 'weight')),
    ).thenAnswer((_) => saving.future);
    await pump(tester);

    await tester.tap(find.byTooltip('বাড়ান ওজন').first);
    await tester.pump();
    expect(find.text('×০.৭৫'), findsOneWidget);
    verify(() => repo.updateMealType('b', weight: 0.75)).called(1);
    saving.complete();
    await tester.pumpAndSettle();
  });
}
