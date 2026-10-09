import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/messages/data/message_repository.dart';
import 'package:meal_bazar/features/messages/domain/message.dart';
import 'package:meal_bazar/features/messages/domain/message_draft.dart';
import 'package:meal_bazar/features/messages/presentation/messages_screens.dart';
import 'package:meal_bazar/features/messages/presentation/new_message_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

final l = lookupAppLocalizations(const Locale('bn'));

const mess = Mess(
  id: 'mess1',
  name: 'Mirpur Mess',
  monthStartDay: 1,
  currency: '৳',
  mealOffCutoff: '22:00:00',
);

Member member(String id, String name, String user, {bool manager = false}) =>
    Member(
      id: id,
      messId: 'mess1',
      displayName: name,
      role: manager ? MemberRole.manager : MemberRole.member,
      status: MemberStatus.active,
      joinedOn: DateTime(2026, 10, 1),
      userId: user,
    );

MessageThread thread(
  String id, {
  String member = 'Rahim',
  bool resolved = false,
  bool unread = false,
  String? refLabel,
  String? lastSender,
}) => MessageThread(
  id: id,
  messId: 'mess1',
  memberId: 'm-$member',
  memberName: member,
  subject: 'Subject $id',
  refType: refLabel == null ? null : 'deposit',
  refLabel: refLabel,
  resolved: resolved,
  isUnread: unread,
  lastBody: 'Last $id',
  lastSenderId: lastSender,
  lastMessageAt: DateTime(2026, 10, 8, 14, 5),
);

ChatMessage msg(String id, String sender, String body) => ChatMessage(
  id: id,
  threadId: 't1',
  senderId: sender,
  body: body,
  createdAt: DateTime(2026, 10, 8, 14),
);

late MockMessageRepository repo;

Future<void> pump(
  WidgetTester tester,
  String location, {
  bool manager = false,
  Object? extra,
}) {
  final router = GoRouter(
    initialLocation: location,
    initialExtra: extra,
    routes: [
      GoRoute(
        path: '/more/messages',
        builder: (_, _) => const MessagesInboxScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, s) =>
                NewMessageScreen(draft: s.extra as MessageDraft?),
          ),
          GoRoute(
            path: ':id',
            builder: (_, s) => ThreadScreen(id: s.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  final me = member('me', 'Karim', 'u1', manager: manager);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        messageRepositoryProvider.overrideWithValue(repo),
        myMembershipsProvider.overrideWith(
          (ref) async => [Membership(member: me, mess: mess)],
        ),
        membersProvider.overrideWith(
          (ref, _) async => [me, member('m-Rahim', 'Rahim', 'u2')],
        ),
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

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    repo = MockMessageRepository();
    when(() => repo.myUserId).thenReturn('u1');
    when(() => repo.markRead(any())).thenAnswer((_) async {});
    when(() => repo.unreadCount(any())).thenAnswer((_) async => 0);
  });

  group('inbox', () {
    testWidgets('manager: member names, unread dot, open/resolved filter', (
      tester,
    ) async {
      when(() => repo.threads('mess1')).thenAnswer(
        (_) async => [
          thread('a', unread: true, refLabel: 'জমা ৳500 · ৮ অক্টোবর'),
          thread('b', member: 'Sumon', lastSender: 'u1'),
          thread('c', member: 'Joy', resolved: true),
        ],
      );
      await pump(tester, '/more/messages', manager: true);
      await tester.pumpAndSettle();

      expect(find.text('Rahim'), findsOneWidget);
      expect(find.text('Sumon'), findsOneWidget);
      expect(find.text('Joy'), findsNothing, reason: 'resolved is filtered');
      expect(find.byKey(const Key('msgUnreadDot')), findsOneWidget);
      expect(find.text(l.msgYou('Last b')), findsOneWidget);
      expect(find.textContaining('জমা ৳500'), findsOneWidget);

      await tester.tap(find.text(l.msgResolved));
      await tester.pumpAndSettle();
      expect(find.text('Joy'), findsOneWidget);
      expect(find.text('Rahim'), findsNothing);
    });

    testWidgets('member: own threads by subject; empty state offers compose', (
      tester,
    ) async {
      when(() => repo.threads('mess1')).thenAnswer((_) async => []);
      await pump(tester, '/more/messages');
      await tester.pumpAndSettle();
      expect(find.text(l.msgEmpty), findsOneWidget);
      expect(find.text(l.msgFilterOpen), findsNothing);
    });

    testWidgets('load error offers retry', (tester) async {
      when(
        () => repo.threads('mess1'),
      ).thenThrow(const AppFailure(FailureKind.network));
      await pump(tester, '/more/messages');
      await tester.pumpAndSettle();
      expect(find.text(l.retry), findsOneWidget);
    });
  });

  group('thread', () {
    setUp(() {
      when(
        () => repo.thread('t1'),
      ).thenAnswer((_) async => thread('t1', refLabel: 'জমা ৳500 · ৮ অক্টোবর'));
    });

    testWidgets('send appends at once, then shows the saved message', (
      tester,
    ) async {
      final server = [msg('x1', 'u2', 'ভুল আছে')];
      when(() => repo.messages('t1')).thenAnswer((_) async => [...server]);
      final gate = Completer<void>();
      when(() => repo.post(any(), 't1', any())).thenAnswer((inv) async {
        await gate.future;
        server.add(msg(inv.positionalArguments[0] as String, 'u1', 'দেখছি'));
      });
      await pump(tester, '/more/messages/t1', manager: true);
      await tester.pumpAndSettle();

      expect(find.text('ভুল আছে'), findsOneWidget);
      expect(find.text('Rahim'), findsWidgets, reason: 'sender name');
      expect(find.textContaining('জমা ৳500'), findsOneWidget, reason: 'ref');
      verify(() => repo.markRead('t1')).called(greaterThanOrEqualTo(1));

      final send = find.byKey(const Key('msgSend'));
      expect(tester.widget<IconButton>(send).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('msgComposer')), 'দেখছি');
      await tester.pump();
      await tester.tap(send);
      await tester.pump();
      expect(find.text('দেখছি'), findsOneWidget);
      expect(find.text(l.msgSending), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('দেখছি'), findsOneWidget);
      expect(find.text(l.msgSending), findsNothing);
    });

    testWidgets('failed send keeps the text and retries with the same id', (
      tester,
    ) async {
      when(() => repo.messages('t1')).thenAnswer((_) async => []);
      when(
        () => repo.post(any(), 't1', any()),
      ).thenThrow(const AppFailure(FailureKind.network));
      await pump(tester, '/more/messages/t1');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('msgComposer')), 'জরুরি');
      await tester.pump();
      await tester.tap(find.byKey(const Key('msgSend')));
      await tester.pumpAndSettle();
      expect(find.text('জরুরি'), findsOneWidget);
      expect(find.text(l.msgNotSent), findsOneWidget);

      await tester.tap(find.text(l.msgNotSent));
      await tester.pumpAndSettle();
      final ids = verify(
        () => repo.post(captureAny(), 't1', 'জরুরি'),
      ).captured.toSet();
      expect(ids, hasLength(1), reason: 'idempotent retry');
    });

    testWidgets('manager resolves', (tester) async {
      when(() => repo.messages('t1')).thenAnswer((_) async => []);
      when(() => repo.setResolved('t1', true)).thenAnswer((_) async {});
      await pump(tester, '/more/messages/t1', manager: true);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.msgResolve));
      await tester.pumpAndSettle();
      verify(() => repo.setResolved('t1', true)).called(1);
    });

    testWidgets('member of an open thread has no status action', (
      tester,
    ) async {
      when(() => repo.messages('t1')).thenAnswer((_) async => []);
      await pump(tester, '/more/messages/t1');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('msgStatusButton')), findsNothing);
    });
  });

  group('compose', () {
    testWidgets('a draft prefills subject and text and sends the ref', (
      tester,
    ) async {
      when(
        () => repo.startThread(
          id: any(named: 'id'),
          messageId: any(named: 'messageId'),
          messId: any(named: 'messId'),
          subject: any(named: 'subject'),
          body: any(named: 'body'),
          memberId: any(named: 'memberId'),
          refType: any(named: 'refType'),
          refId: any(named: 'refId'),
          refLabel: any(named: 'refLabel'),
        ),
      ).thenAnswer((_) async {});
      when(() => repo.threads(any())).thenAnswer((_) async => []);
      when(() => repo.thread(any())).thenAnswer((_) async => null);
      when(() => repo.messages(any())).thenAnswer((_) async => []);
      await pump(
        tester,
        '/more/messages/new',
        extra: const MessageDraft(
          refType: 'deposit',
          refId: 'd1',
          refLabel: 'জমা ৳500 · ৮ অক্টোবর',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('সমস্যা: জমা ৳500 · ৮ অক্টোবর'), findsOneWidget);
      expect(find.text(l.msgReportStarter), findsOneWidget);
      expect(find.text(l.msgToManagers), findsOneWidget);

      await tester.tap(find.byKey(const Key('msgSendButton')));
      await tester.pumpAndSettle();
      verify(
        () => repo.startThread(
          id: any(named: 'id'),
          messageId: any(named: 'messageId'),
          messId: 'mess1',
          subject: 'সমস্যা: জমা ৳500 · ৮ অক্টোবর',
          body: l.msgReportStarter,
          refType: 'deposit',
          refId: 'd1',
          refLabel: 'জমা ৳500 · ৮ অক্টোবর',
        ),
      ).called(1);
    });

    testWidgets('offline: error shown, text kept', (tester) async {
      when(
        () => repo.startThread(
          id: any(named: 'id'),
          messageId: any(named: 'messageId'),
          messId: any(named: 'messId'),
          subject: any(named: 'subject'),
          body: any(named: 'body'),
          memberId: any(named: 'memberId'),
          refType: any(named: 'refType'),
          refId: any(named: 'refId'),
          refLabel: any(named: 'refLabel'),
        ),
      ).thenThrow(const AppFailure(FailureKind.network));
      await pump(tester, '/more/messages/new');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('msgSubjectField')), 'পানি');
      await tester.enterText(find.byKey(const Key('msgBodyField')), 'নেই');
      await tester.tap(find.byKey(const Key('msgSendButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('msgSendError')), findsOneWidget);
      expect(find.text('পানি'), findsOneWidget);
      expect(find.text('নেই'), findsOneWidget);
    });

    testWidgets('a manager must pick the member', (tester) async {
      await pump(tester, '/more/messages/new', manager: true);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('msgSubjectField')), 'ভাড়া');
      await tester.enterText(find.byKey(const Key('msgBodyField')), 'দিও');
      await tester.tap(find.byKey(const Key('msgSendButton')));
      await tester.pumpAndSettle();
      expect(find.text(l.msgMemberRequired), findsOneWidget);
    });
  });
}
