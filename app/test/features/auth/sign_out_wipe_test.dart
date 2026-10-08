import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/db/db.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/data/auth_repository.dart';
import 'package:meal_bazar/features/mess/presentation/common.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Future<void> queueOne(AppDb db) =>
    db.enqueue('meal_entries', 'k', 'op1', {'mess_id': 'mess1'});

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('auth state: sign-out and a new user wipe the local DB', () async {
    final db = AppDb(NativeDatabase.memory());
    final auth = MockAuthRepository();
    final users = StreamController<String?>();
    when(auth.authStateChanges).thenAnswer((_) => users.stream);
    final c = ProviderContainer(
      overrides: [
        appDbProvider.overrideWithValue(db),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await users.close();
      await db.close();
    });
    final sub = c.listen(authStateProvider, (_, _) {});

    Future<void> emit(String? uid) async {
      users.add(uid);
      await c.read(authStateProvider.future);
      await pumpEventQueue();
    }

    await emit('alice');
    await queueOne(db);
    await emit('alice'); // token refresh: same user keeps data
    expect(await db.unsentCount(), 1);

    await emit(null);
    expect(await db.unsentCount(), 0);

    await emit('alice');
    await queueOne(db);
    await emit('bob');
    expect(await db.unsentCount(), 0);
    sub.close();
  });

  testWidgets('sign-out confirm warns about unsent offline entries', (
    tester,
  ) async {
    final db = AppDb(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    await tester.runAsync(() => queueOne(db));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDbProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('bn'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => confirmSignOut(context, ref),
              child: const Text('out'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('out'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'অফলাইনে সেভ করা ১ টি এন্ট্রি এখনো পাঠানো হয়নি — সাইন আউট করলে মুছে যাবে',
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
