import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';
import 'package:meal_bazar/features/auth/application/auth_providers.dart';
import 'package:meal_bazar/features/push/application/push_service.dart';
import 'package:meal_bazar/features/push/data/push_repository.dart';
import 'package:meal_bazar/features/push/domain/push.dart';
import 'package:meal_bazar/features/push/presentation/inbox_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockPushRepository extends Mock implements PushRepository {}

final l = lookupAppLocalizations(const Locale('bn'));

InboxItem item(
  int id, {
  required DateTime at,
  bool read = false,
  String type = 'deposit_added',
  String? route = '/more/target',
}) => InboxItem(
  id: id,
  type: type,
  title: 'Title $id',
  body: 'Body $id',
  route: route,
  createdAt: at,
  isRead: read,
);

void main() {
  group('repository', () {
    late List<http.Request> requests;
    late PushRepository repo;

    setUp(() {
      requests = [];
      final client = SupabaseClient(
        'http://localhost:54321',
        'anon',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          requests.add(r);
          final body = switch (r.url.path) {
            '/rest/v1/notifications' => jsonEncode([
              {
                'id': 7,
                'type': 'notice',
                'title': 'T',
                'body': 'B',
                'route': '/more/notices/1',
                'created_at': '2026-10-09T04:00:00Z',
                'read_at': null,
              },
            ]),
            '/rest/v1/rpc/unread_notification_count' => '3',
            _ => 'null',
          };
          return http.Response(
            body,
            200,
            headers: {'content-type': 'application/json'},
            request: r,
          );
        }),
      );
      repo = PushRepository(client);
    });

    test('inbox is newest first (explicit descending order)', () async {
      final rows = await repo.inbox();
      final q = requests.single.url.queryParameters;
      expect(q['order'], 'created_at.desc.nullslast,id.desc.nullslast');
      expect(rows.single.id, 7);
      expect(rows.single.isRead, isFalse);
      expect(rows.single.pushType, PushType.notice);
    });

    test('unread count and mark read RPCs', () async {
      expect(await repo.unreadInboxCount(), 3);
      await repo.markInboxRead([7]);
      await repo.markInboxRead();
      expect(requests.map((r) => r.url.path), [
        '/rest/v1/rpc/unread_notification_count',
        '/rest/v1/rpc/mark_notifications_read',
        '/rest/v1/rpc/mark_notifications_read',
      ]);
      expect(jsonDecode(requests[1].body), {
        'p_ids': [7],
      });
      expect(jsonDecode(requests[2].body), {'p_ids': null});
    });
  });

  test('inboxByDay groups newest-first rows by local day', () {
    final groups = inboxByDay([
      item(3, at: DateTime(2026, 10, 9, 20)),
      item(2, at: DateTime(2026, 10, 9, 8)),
      item(1, at: DateTime(2026, 10, 7, 23)),
    ]);
    expect(groups.map((g) => g.$1), [
      DateTime(2026, 10, 9),
      DateTime(2026, 10, 7),
    ]);
    expect(groups.first.$2.map((i) => i.id), [3, 2]);
  });

  group('InboxScreen', () {
    late MockPushRepository repo;

    setUp(() {
      repo = MockPushRepository();
      when(() => repo.unreadInboxCount()).thenAnswer((_) async => 0);
      when(() => repo.markInboxRead(any())).thenAnswer((_) async {});
      when(() => repo.markInboxRead()).thenAnswer((_) async {});
    });

    Future<void> pump(
      WidgetTester tester, {
      String at = '/more/notifications/inbox',
    }) async {
      final router = GoRouter(
        initialLocation: at,
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) =>
                Scaffold(appBar: AppBar(actions: const [InboxBell()])),
          ),
          GoRoute(
            path: '/more/notifications/inbox',
            builder: (_, _) => const InboxScreen(),
          ),
          GoRoute(
            path: '/more/target',
            builder: (_, _) => const Scaffold(body: Text('target screen')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            pushRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWithValue(const AsyncData('me')),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            locale: const Locale('bn'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
    }

    testWidgets('loading, then empty', (tester) async {
      when(
        () => repo.inbox(),
      ).thenAnswer((_) => Future.delayed(const Duration(seconds: 1), () => []));
      await pump(tester);
      await tester.pump();
      expect(find.byType(LoadingView), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(l.inboxEmpty), findsOneWidget);
      expect(find.text(l.inboxMarkAllRead), findsNothing);
    });

    testWidgets('error with retry', (tester) async {
      var fail = true;
      when(() => repo.inbox()).thenAnswer((_) async {
        if (fail) throw const AppFailure(FailureKind.network);
        return [item(1, at: DateTime.now())];
      });
      await pump(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ErrorView), findsOneWidget);
      fail = false;
      await tester.tap(find.text(l.retry));
      await tester.pumpAndSettle();
      expect(find.text('Title 1'), findsOneWidget);
    });

    testWidgets('grouped by day; tap marks read and opens; mark all read', (
      tester,
    ) async {
      final now = DateTime.now();
      when(() => repo.inbox()).thenAnswer(
        (_) async => [
          item(3, at: now),
          item(2, at: now.subtract(const Duration(days: 1))),
          item(1, at: now.subtract(const Duration(days: 1)), read: true),
        ],
      );
      await pump(tester);
      await tester.pumpAndSettle();
      expect(find.text(l.todayIsToday), findsOneWidget);
      expect(find.text(l.dayYesterday), findsOneWidget);
      expect(find.text('Title 1'), findsOneWidget);

      await tester.tap(find.text(l.inboxMarkAllRead));
      await tester.pumpAndSettle();
      verify(() => repo.markInboxRead()).called(1);
      expect(find.text(l.inboxMarkAllRead), findsNothing);
    });

    testWidgets('tap marks that one read and pushes its route', (tester) async {
      when(
        () => repo.inbox(),
      ).thenAnswer((_) async => [item(5, at: DateTime.now())]);
      await pump(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Title 5'));
      await tester.pumpAndSettle();
      verify(() => repo.markInboxRead([5])).called(1);
      expect(find.text('target screen'), findsOneWidget);
    });

    testWidgets('Home bell shows my unread count and opens the inbox', (
      tester,
    ) async {
      when(() => repo.unreadInboxCount()).thenAnswer((_) async => 3);
      when(() => repo.inbox()).thenAnswer((_) async => []);
      await pump(tester, at: '/home');
      await tester.pumpAndSettle();
      expect(find.text('৩'), findsOneWidget);
      await tester.tap(find.byKey(const Key('inboxBell')));
      await tester.pumpAndSettle();
      expect(find.byType(InboxScreen), findsOneWidget);
    });
  });
}
