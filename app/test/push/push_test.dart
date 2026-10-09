import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/db/db.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/auth/data/auth_repository.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/push/application/push_service.dart';
import 'package:meal_bazar/features/push/data/push_repository.dart';
import 'package:meal_bazar/features/push/domain/push.dart';
import 'package:meal_bazar/features/push/presentation/push_screens.dart';
import 'package:meal_bazar/features/reminders/application/reminder_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../reminders/reminders_test.dart' show FakeNotifications;

class MockPushRepository extends Mock implements PushRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAppDb extends Mock implements AppDb {}

class FakeMessaging implements PushMessaging {
  bool available = true;
  int inits = 0;
  String? currentToken = 'tok-1';
  RemoteMessage? initial;
  final refresh = StreamController<String>.broadcast();
  final messages = StreamController<RemoteMessage>.broadcast();
  final opened = StreamController<RemoteMessage>.broadcast();

  @override
  Future<bool> init() async {
    inits++;
    return available;
  }

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<RemoteMessage> get onMessage => messages.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => opened.stream;

  @override
  Future<RemoteMessage?> initialMessage() async => initial;
}

RemoteMessage push(String route, {String title = 'নতুন বাজার'}) =>
    RemoteMessage(
      data: {'route': route, 'type': 'bazar_added'},
      notification: RemoteNotification(title: title, body: 'Push Mess: ৳৩০০'),
    );

void main() {
  setUpAll(() => registerFallbackValue(const NotificationPrefs()));

  group('domain', () {
    test('a missing pref is on; toggling keeps unknown keys', () {
      const p = NotificationPrefs({'notice': false, 'future_type': true});
      expect(p.isOn(PushType.notice), isFalse);
      expect(p.isOn(PushType.bazarAdded), isTrue);
      final q = p.toggled(PushType.bazarAdded, false);
      expect(q.raw, {
        'notice': false,
        'future_type': true,
        'bazar_added': false,
      });
      expect(NotificationPrefs.fromJson('garbage').isOn(PushType.notice), true);
    });

    test('keys match the server types', () {
      expect(PushType.values.map((t) => t.key), [
        'join_request',
        'deposit_pending',
        'deposit_verified',
        'deposit_rejected',
        'notice',
        'bazar_added',
        'expense_added',
        'month_closed',
        'due_reminder',
      ]);
    });

    test('only in-app routes are followed', () {
      expect(pushRoute({'route': '/money'}), '/money');
      expect(pushRoute({'route': 'https://evil.example'}), isNull);
      expect(pushRoute({}), isNull);
    });

    test('TOO_SOON maps to rate limited', () {
      expect(
        mapError(const PostgrestException(message: 'TOO_SOON')).kind,
        FailureKind.rateLimited,
      );
    });
  });

  group('PushService', () {
    late FakeMessaging messaging;
    late MockPushRepository repo;
    late FakeNotifications notes;
    late List<String> routes;
    late PushService service;

    setUp(() {
      messaging = FakeMessaging();
      repo = MockPushRepository();
      notes = FakeNotifications();
      routes = [];
      when(() => repo.registerToken(any(), any())).thenAnswer((_) async {});
      when(() => repo.unregisterToken(any())).thenAnswer((_) async {});
      service = PushService(
        messaging: messaging,
        repo: repo,
        notifications: notes,
        navigate: routes.add,
      );
    });

    test('registers the token on sign-in and again on refresh', () async {
      await service.sync(signedIn: true, enabled: true);
      verify(() => repo.registerToken('tok-1', 'android')).called(1);
      messaging.refresh.add('tok-2');
      await pumpEventQueue();
      verify(() => repo.registerToken('tok-2', 'android')).called(1);
    });

    test('signed out or flag off: Firebase is not even started', () async {
      await service.sync(signedIn: false, enabled: true);
      await service.sync(signedIn: true, enabled: false);
      expect(messaging.inits, 0);
      verifyNever(() => repo.registerToken(any(), any()));
    });

    test('no Firebase config: silently off', () async {
      messaging.available = false;
      await service.sync(signedIn: true, enabled: true);
      verifyNever(() => repo.registerToken(any(), any()));
    });

    test('a refresh after sign-out is not registered', () async {
      await service.sync(signedIn: true, enabled: true);
      await service.unregister();
      messaging.refresh.add('tok-3');
      await pumpEventQueue();
      verifyNever(() => repo.registerToken('tok-3', any()));
    });

    test('foreground push is shown locally with its route', () async {
      await service.sync(signedIn: true, enabled: true);
      messaging.messages.add(push('/bazar'));
      await pumpEventQueue();
      expect(notes.shown.single.title, 'নতুন বাজার');
      expect(notes.shown.single.route, '/bazar');
      expect(notes.shown.single.id, inInclusiveRange(1000, 1001000));
    });

    test('taps from background and cold start navigate', () async {
      messaging.initial = push('/money/months');
      await service.sync(signedIn: true, enabled: true);
      messaging.opened.add(push('/more/notices/n1'));
      await pumpEventQueue();
      expect(routes, ['/money/months', '/more/notices/n1']);
    });

    test('listeners are wired once across syncs', () async {
      await service.sync(signedIn: true, enabled: true);
      await service.sync(signedIn: true, enabled: true);
      messaging.opened.add(push('/money'));
      await pumpEventQueue();
      expect(routes, ['/money']);
    });

    test('unregister removes the token and never throws', () async {
      await service.sync(signedIn: true, enabled: true);
      when(
        () => repo.unregisterToken(any()),
      ).thenThrow(const AppFailure(FailureKind.network));
      await service.unregister();
      verify(() => repo.unregisterToken('tok-1')).called(1);
    });

    test('unregister without a registration this run asks Firebase', () async {
      await service.unregister();
      verify(() => repo.unregisterToken('tok-1')).called(1);
    });
  });

  test('sign-out removes the device before the session goes', () async {
    final client = MockSupabaseClient();
    final auth = MockGoTrueClient();
    final calls = <String>[];
    when(() => client.auth).thenReturn(auth);
    when(auth.signOut).thenAnswer((_) async => calls.add('signOut'));
    final repo = AuthRepository(
      client,
      MockAppDb(),
      beforeSignOut: () async => calls.add('unregister'),
    );
    await repo.signOut();
    expect(calls, ['unregister', 'signOut']);
  });

  group('NotificationSettingsScreen', () {
    late MockPushRepository repo;

    Future<void> pump(WidgetTester tester, {required bool manager}) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            pushRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWithValue(const AsyncData('me')),
            localNotificationsProvider.overrideWithValue(
              FakeNotifications()..allowed = true,
            ),
            amIManagerProvider.overrideWithValue(manager),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const NotificationSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    bool switchOn(WidgetTester tester, String title) => tester
        .widget<SwitchListTile>(
          find.ancestor(
            of: find.text(title),
            matching: find.byType(SwitchListTile),
          ),
        )
        .value;

    setUp(() {
      repo = MockPushRepository();
      when(repo.fetchPrefs).thenAnswer(
        (_) async => const NotificationPrefs({'bazar_added': false}),
      );
      when(() => repo.savePrefs(any())).thenAnswer((_) async {});
    });

    testWidgets('members see their switches, saved prefs applied', (
      tester,
    ) async {
      await pump(tester, manager: false);
      expect(find.text('Join requests'), findsNothing);
      expect(find.text('Deposits to verify'), findsNothing);
      expect(switchOn(tester, 'New bazar'), isFalse);
      expect(switchOn(tester, 'New notices'), isTrue);
      expect(find.byType(SwitchListTile), findsNWidgets(7));
    });

    testWidgets('managers also get join requests and deposits to verify', (
      tester,
    ) async {
      await pump(tester, manager: true);
      expect(find.byType(SwitchListTile), findsNWidgets(9));
    });

    testWidgets('a toggle saves the whole map', (tester) async {
      await pump(tester, manager: false);
      await tester.tap(find.text('New notices'));
      await tester.pumpAndSettle();
      final saved =
          verify(() => repo.savePrefs(captureAny())).captured.single
              as NotificationPrefs;
      expect(saved.raw, {'bazar_added': false, 'notice': false});
      expect(switchOn(tester, 'New notices'), isFalse);
    });

    testWidgets('a failed save rolls back and says so', (tester) async {
      when(
        () => repo.savePrefs(any()),
      ).thenThrow(const AppFailure(FailureKind.network));
      await pump(tester, manager: false);
      await tester.tap(find.text('New notices'));
      await tester.pumpAndSettle();
      expect(switchOn(tester, 'New notices'), isTrue);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('load error offers retry', (tester) async {
      when(repo.fetchPrefs).thenThrow(const AppFailure(FailureKind.network));
      await pump(tester, manager: false);
      expect(find.byType(SwitchListTile), findsNothing);
      when(repo.fetchPrefs).thenAnswer((_) async => const NotificationPrefs());
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byType(SwitchListTile), findsNWidgets(7));
    });
  });

  group('SendDueRemindersButton', () {
    late MockPushRepository repo;

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [pushRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SendDueRemindersButton(messId: 'm1')),
          ),
        ),
      );
    }

    setUp(() => repo = MockPushRepository());

    testWidgets('cancel sends nothing', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Remind members who owe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => repo.sendDueReminders(any()));
    });

    testWidgets('confirm sends and reports the count', (tester) async {
      when(() => repo.sendDueReminders('m1')).thenAnswer((_) async => 3);
      await pump(tester);
      await tester.tap(find.text('Remind members who owe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Reminder sent to 3'), findsOneWidget);
    });

    testWidgets('nobody reachable says so', (tester) async {
      when(() => repo.sendDueReminders('m1')).thenAnswer((_) async => 0);
      await pump(tester);
      await tester.tap(find.text('Remind members who owe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "Nobody to notify: members who owe don't have notifications on",
        ),
        findsOneWidget,
      );
    });
  });
}
