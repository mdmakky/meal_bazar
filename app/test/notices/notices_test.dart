import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/mess/presentation/more_screens.dart';
import 'package:meal_bazar/features/notices/data/notice_repository.dart';
import 'package:meal_bazar/features/notices/domain/notice.dart';
import 'package:meal_bazar/features/notices/presentation/latest_notice_banner.dart';
import 'package:meal_bazar/features/notices/presentation/notices_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockNoticeRepository extends Mock implements NoticeRepository {}

final l = lookupAppLocalizations(const Locale('bn'));

const mess = Mess(
  id: 'mess1',
  name: 'Mirpur Mess',
  monthStartDay: 1,
  currency: '৳',
  mealOffCutoff: '22:00:00',
);

Notice notice(
  String id, {
  bool pinned = false,
  bool read = false,
  int day = 1,
  DateTime? expiresAt,
}) => Notice(
  id: id,
  messId: 'mess1',
  title: 'Notice $id',
  body: 'Body $id',
  pinned: pinned,
  isRead: read,
  expiresAt: expiresAt,
  createdAt: DateTime(2026, 10, day),
);

late MockNoticeRepository repo;

Future<void> pump(
  WidgetTester tester,
  String location, {
  bool manager = true,
  List<Notice> notices = const [],
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
      GoRoute(
        path: '/banner',
        builder: (_, _) => const Scaffold(body: HomeNotices()),
      ),
      GoRoute(
        path: '/more/notices',
        builder: (_, _) => const NoticesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) => NoticeDetailScreen(id: s.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  when(() => repo.feed('mess1')).thenAnswer((_) async => notices);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        noticeRepositoryProvider.overrideWithValue(repo),
        myMembershipsProvider.overrideWith(
          (ref) async => [
            Membership(
              member: Member(
                id: 'me',
                messId: 'mess1',
                displayName: 'Rahim',
                role: manager ? MemberRole.manager : MemberRole.member,
                status: MemberStatus.active,
                joinedOn: DateTime(2026, 10, 1),
                userId: 'u1',
              ),
              mess: mess,
            ),
          ],
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
  setUp(() => repo = MockNoticeRepository());

  test('visibleNotices: pinned first, newest first, expired dropped', () {
    final now = DateTime(2026, 10, 9, 12);
    final list = visibleNotices([
      notice('old', day: 1),
      notice('new', day: 5),
      notice('pinOld', pinned: true, day: 2),
      notice('pinNew', pinned: true, day: 4),
      notice('gone', day: 8, expiresAt: DateTime(2026, 10, 9)),
      notice('live', day: 3, expiresAt: DateTime(2026, 10, 10)),
    ], now);
    expect(list.map((n) => n.id), ['pinNew', 'pinOld', 'new', 'live', 'old']);
  });

  testWidgets('list shows pinned first and an unread dot per unread', (
    tester,
  ) async {
    await pump(
      tester,
      '/more/notices',
      notices: [
        notice('a', day: 5),
        notice('b', pinned: true, read: true, day: 1),
        notice('c', day: 3),
      ],
    );
    await tester.pumpAndSettle();
    final ys = [
      for (final t in ['Notice b', 'Notice a', 'Notice c'])
        tester.getTopLeft(find.text(t)).dy,
    ];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.byKey(const Key('noticeUnreadDot')), findsNWidgets(2));
  });

  testWidgets('More tile shows the unread count', (tester) async {
    await pump(
      tester,
      '/more',
      notices: [notice('a'), notice('b'), notice('c', read: true)],
    );
    await tester.pumpAndSettle();
    // More has grown past one screen; the list builds rows lazily.
    await tester.scrollUntilVisible(find.text(l.noticeTitle), 200);
    expect(find.text(l.noticeTitle), findsOneWidget);
    expect(find.text('২'), findsOneWidget);
  });

  testWidgets('compose: empty title is rejected, valid one saves', (
    tester,
  ) async {
    when(
      () => repo.save(
        id: any(named: 'id'),
        messId: any(named: 'messId'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        pinned: any(named: 'pinned'),
        expiresAt: any(named: 'expiresAt'),
      ),
    ).thenAnswer((_) async {});
    await pump(tester, '/more/notices');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l.noticeSave));
    await tester.pumpAndSettle();
    expect(find.text(l.noticeTitleRequired), findsOneWidget);
    verifyNever(
      () => repo.save(
        id: any(named: 'id'),
        messId: any(named: 'messId'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        pinned: any(named: 'pinned'),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('noticeTitleField')),
      '  পানি বন্ধ  ',
    );
    await tester.tap(find.text(l.noticePin));
    await tester.tap(find.text(l.noticeSave));
    await tester.pumpAndSettle();
    verify(
      () => repo.save(
        id: any(named: 'id'),
        messId: 'mess1',
        title: 'পানি বন্ধ',
        body: '',
        pinned: true,
      ),
    ).called(1);
    expect(find.text(l.noticeSaved), findsOneWidget);
  });

  testWidgets('member: no compose, no edit/delete; opening marks read', (
    tester,
  ) async {
    when(() => repo.markRead('a', 'me')).thenAnswer((_) async {});
    await pump(tester, '/more/notices', manager: false, notices: [notice('a')]);
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.text('Notice a'));
    await tester.pumpAndSettle();
    expect(find.text('Body a'), findsOneWidget);
    expect(find.byTooltip(l.edit), findsNothing);
    expect(find.byTooltip(l.delete), findsNothing);
    verify(() => repo.markRead('a', 'me')).called(1);
  });

  testWidgets('manager deletes after confirming', (tester) async {
    when(() => repo.delete('a')).thenAnswer((_) async {});
    await pump(tester, '/more/notices', notices: [notice('a', read: true)]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notice a'));
    await tester.pumpAndSettle();
    expect(find.byTooltip(l.edit), findsOneWidget);

    await tester.tap(find.byTooltip(l.delete));
    await tester.pumpAndSettle();
    expect(find.text(l.noticeDeleteConfirmTitle), findsOneWidget);
    await tester.tap(find.text(l.cancel));
    await tester.pumpAndSettle();
    verifyNever(() => repo.delete('a'));

    await tester.tap(find.byTooltip(l.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, l.delete));
    await tester.pumpAndSettle();
    verify(() => repo.delete('a')).called(1);
    verifyNever(() => repo.markRead(any(), any()));
  });

  test('homeNotices: pinned or expiring stay when read, others until read', () {
    final now = DateTime(2026, 10, 9, 12);
    final list = homeNotices(
      visibleNotices([
        notice('readPlain', read: true, day: 8),
        notice('unreadPlain', day: 7),
        notice('readPinned', pinned: true, read: true, day: 2),
        notice(
          'readExpiring',
          read: true,
          day: 3,
          expiresAt: DateTime(2026, 11, 6),
        ),
        notice(
          'expired',
          pinned: true,
          day: 9,
          expiresAt: DateTime(2026, 10, 9),
        ),
      ], now),
    );
    expect(list.map((n) => n.id), [
      'readPinned',
      'unreadPlain',
      'readExpiring',
    ]);
  });

  testWidgets('Home shows up to 3 notices, read ones dimmed, expiry, a link', (
    tester,
  ) async {
    await pump(
      tester,
      '/banner',
      notices: [
        notice('p1', pinned: true, read: true, day: 9),
        notice('e1', day: 8, read: true, expiresAt: DateTime(2099, 11, 6)),
        notice('u1', day: 7),
        notice('u2', day: 6),
        notice('gone', day: 5, read: true),
      ],
    );
    await tester.pumpAndSettle();
    // A swipeable strip: the first card, the next one peeking, dots below.
    expect(find.byKey(const Key('noticeCarousel')), findsOneWidget);
    expect(find.text('Notice p1'), findsOneWidget);
    expect(find.text('Notice u1'), findsNothing);
    await tester.drag(
      find.byKey(const Key('noticeCarousel')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('noticeCarousel')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notice u1'), findsOneWidget);
    expect(find.text('Notice u2'), findsNothing);
    expect(find.text('Notice gone'), findsNothing);
    expect(find.text(l.homeNoticeAll), findsOneWidget);
    // The unread one's dot is lit.
    expect(find.byKey(const Key('homeNoticeUnreadDot')), findsWidgets);

    await tester.tap(find.text(l.homeNoticeAll));
    await tester.pumpAndSettle();
    expect(find.byType(NoticesScreen), findsOneWidget);
  });

  testWidgets('Home shows nothing without notices', (tester) async {
    await pump(tester, '/banner', notices: [notice('r', read: true)]);
    await tester.pumpAndSettle();
    expect(find.text('Notice r'), findsNothing);
    expect(find.byType(AppCard), findsNothing);
  });

  for (final manager in [true, false]) {
    testWidgets(
      'More: ${manager ? 'manager sees the audit log' : 'member sees my activity'}',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 7200);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await pump(tester, '/more', manager: manager);
        await tester.pumpAndSettle();
        expect(
          find.text(l.auditTitle),
          manager ? findsOneWidget : findsNothing,
        );
        expect(
          find.text(l.activityMoreTile),
          manager ? findsNothing : findsOneWidget,
        );
      },
    );
  }
}
