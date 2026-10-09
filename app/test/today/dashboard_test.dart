import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_bazar/core/dates.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/core/widgets/widgets.dart';
import 'package:meal_bazar/features/audit/application/audit_providers.dart';
import 'package:meal_bazar/features/audit/domain/audit.dart';
import 'package:meal_bazar/features/meals/application/meal_providers.dart';
import 'package:meal_bazar/features/meals/data/meal_repository.dart';
import 'package:meal_bazar/features/meals/domain/meal.dart';
import 'package:meal_bazar/features/messages/application/unread_provider.dart';
import 'package:meal_bazar/features/messages/domain/message_draft.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/mess/domain/member.dart';
import 'package:meal_bazar/features/mess/domain/mess.dart';
import 'package:meal_bazar/features/month/application/month_providers.dart';
import 'package:meal_bazar/features/month/domain/month.dart';
import 'package:meal_bazar/features/today/presentation/dashboard.dart';
import 'package:meal_bazar/features/today/presentation/today_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../platform/fixed_config.dart';

class MockMealRepository extends Mock implements MealRepository {}

final l = lookupAppLocalizations(const Locale('bn'));

const mess = Mess(
  id: 'mess1',
  name: 'Mirpur Mess',
  monthStartDay: 1,
  currency: '৳',
  mealOffCutoff: '22:00:00',
);

Member member(
  String id,
  String name, {
  MemberStatus status = MemberStatus.active,
  MemberRole role = MemberRole.member,
}) => Member(
  id: id,
  messId: 'mess1',
  displayName: name,
  role: role,
  status: status,
  joinedOn: DateTime(2026, 1, 1),
  userId: 'u-$id',
);

MemberBalance balance(String id, String name, double closing) => MemberBalance(
  memberId: id,
  displayName: name,
  meals: 10,
  foodCost: 687.80,
  extraCost: 250,
  credit: 1500,
  openingBalance: 0,
  closingBalance: closing,
);

const totals = MonthTotals(
  foodTotal: 1710,
  totalMeals: 20.5,
  mealRate: 83.41,
  extraTotal: 500,
  creditTotal: 3000,
);

final now = today();
final period = MonthPeriod(
  DateTime(now.year, now.month),
  DateTime(now.year, now.month + 1),
);

const noAttention = (
  pendingDeposits: 0,
  pendingMembers: 0,
  mealsMissing: 0,
  pendingRecurring: 0,
);

/// Six periods, oldest first; the first [empty] have no spending at all.
List<MonthPoint> history({int empty = 3}) => [
  for (var i = 5; i >= 0; i--)
    (
      start: DateTime(2026, 10 - i),
      foodTotal: 5 - i < empty ? 0.0 : 1000.0,
      extraTotal: 0.0,
      mealRate: 5 - i < empty ? 0.0 : 60.0 + i,
    ),
];

AuditEntry depositVerified() => AuditEntry(
  id: 7,
  action: 'update',
  entity: 'deposits',
  at: DateTime(2026, 10, 5, 14, 30),
  actorId: 'u-rahim',
  entityId: 'd1',
  refType: 'deposit',
  refId: 'd1',
  oldRow: const {'member_id': 'karim', 'amount': 500, 'status': 'pending'},
  newRow: const {'member_id': 'karim', 'amount': 500, 'status': 'verified'},
);

List<Override> overrides({
  bool manager = true,
  Attention attention = noAttention,
  int unread = 0,
  List<CategoryTotal>? categories,
  List<MonthPoint>? months,
  List<AuditEntry>? activity,
  bool failCash = false,
  List<Member>? members,
  List<MemberTransparency>? transparency,
}) => [
  myMembershipsProvider.overrideWith(
    (ref) async => [
      Membership(
        member: manager
            ? member('rahim', 'Rahim', role: MemberRole.manager)
            : member('karim', 'Karim'),
        mess: mess,
      ),
    ],
  ),
  amIManagerProvider.overrideWithValue(manager),
  membersProvider.overrideWith(
    (ref, id) async =>
        members ??
        [
          member('rahim', 'Rahim', role: MemberRole.manager),
          member('karim', 'Karim'),
          member('selim', 'Selim'),
        ],
  ),
  currentPeriodProvider.overrideWith((ref, id) async => period),
  monthTotalsProvider.overrideWith((ref, id) async => totals),
  memberBalancesProvider.overrideWith(
    (ref, id) async => [
      balance('rahim', 'Rahim', 424.63),
      balance('selim', 'Selim', -100),
      balance('karim', 'Karim', -834.63),
    ],
  ),
  attentionProvider.overrideWith((ref, id) async => attention),
  unreadMessagesCountProvider.overrideWith((ref, id) async => unread),
  messCashProvider.overrideWith(
    (ref, id) async => failCash
        ? throw const AppFailure(FailureKind.network)
        : (
            depositsIn: 3000.0,
            fundSpent: 1200.0,
            cash: 1800.0,
            pendingDeposits: 700.0,
          ),
  ),
  transparencyProvider.overrideWith(
    (ref, id) async =>
        transparency ??
        const [
          (
            memberId: 'karim',
            displayName: 'Karim',
            deposits: 2000.0,
            ownPocket: 300.0,
            closingBalance: -834.63,
          ),
          (
            memberId: 'rahim',
            displayName: 'Rahim',
            deposits: 1000.0,
            ownPocket: 0.0,
            closingBalance: 424.63,
          ),
        ],
  ),
  myActivityProvider.overrideWith(
    (ref, id) async => activity ?? [depositVerified()],
  ),
  spendingByCategoryProvider.overrideWith(
    (ref, id) async =>
        categories ??
        const [
          (category: 'বাজার', total: 1410.0, isBazar: true),
          (category: 'ওয়াইফাই', total: 500.0, isBazar: false),
        ],
  ),
  monthHistoryProvider.overrideWith((ref, id) async => months ?? history()),
];

MessageDraft? draft;

Future<void> pumpDashboard(
  WidgetTester tester, {
  bool manager = true,
  Locale locale = const Locale('bn'),
  List<Override> extra = const [],
  Attention attention = noAttention,
  int unread = 0,
  List<CategoryTotal>? categories,
  List<MonthPoint>? months,
  List<AuditEntry>? activity,
  bool failCash = false,
  List<Member>? members,
  List<MemberTransparency>? transparency,
}) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  draft = null;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: SingleChildScrollView(
            child: MonthDashboard(messId: 'mess1', manager: manager),
          ),
        ),
      ),
      GoRoute(path: '/money', builder: (_, s) => Text('money ${s.uri}')),
      GoRoute(path: '/meals', builder: (_, _) => const Text('meals tab')),
      GoRoute(
        path: '/more/messages/new',
        builder: (_, s) {
          draft = s.extra as MessageDraft?;
          return const Text('new message');
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        ...overrides(
          manager: manager,
          attention: attention,
          unread: unread,
          categories: categories,
          months: months,
          activity: activity,
          failCash: failCash,
          members: members,
          transparency: transparency,
        ),
        ...extra,
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('manager', () {
    testWidgets('needs attention: only rows with a count, each opens its '
        'screen', (tester) async {
      await pumpDashboard(
        tester,
        attention: (
          pendingDeposits: 2,
          pendingMembers: 0,
          mealsMissing: 3,
          pendingRecurring: 0,
        ),
      );
      expect(find.text(l.attnTitle), findsOneWidget);
      expect(find.text(l.attnDeposits('২')), findsOneWidget);
      expect(find.text(l.attnMeals('৩')), findsOneWidget);
      expect(find.text(l.attnJoin('০')), findsNothing);
      expect(find.text(l.attnMessages('০')), findsNothing);
      expect(find.text(l.recurringPending('০')), findsNothing);

      await tester.tap(find.text(l.attnDeposits('২')));
      await tester.pumpAndSettle();
      expect(find.text('money /money?tab=deposit'), findsOneWidget);
    });

    testWidgets('needs attention: join requests, messages, bills', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        unread: 4,
        attention: (
          pendingDeposits: 0,
          pendingMembers: 1,
          mealsMissing: 0,
          pendingRecurring: 2,
        ),
      );
      expect(find.text(l.attnJoin('১')), findsOneWidget);
      expect(find.text(l.attnMessages('৪')), findsOneWidget);
      expect(find.text(l.recurringPending('২')), findsOneWidget);
      expect(find.text(l.attnDeposits('০')), findsNothing);
    });

    testWidgets('nothing to do: no attention card at all', (tester) async {
      await pumpDashboard(tester);
      expect(find.text(l.attnTitle), findsNothing);
    });

    testWidgets('flags hide deposit and bill rows', (tester) async {
      await pumpDashboard(
        tester,
        extra: [
          flagsOff(['member_deposits', 'recurring']),
        ],
        attention: (
          pendingDeposits: 2,
          pendingMembers: 0,
          mealsMissing: 0,
          pendingRecurring: 2,
        ),
      );
      expect(find.text(l.attnTitle), findsNothing);
    });

    testWidgets('cash in hand: the SQL figure with its proof', (tester) async {
      await pumpDashboard(tester);
      expect(find.text(l.cashTitle), findsOneWidget);
      expect(find.text('৳১,৮০০'), findsOneWidget);
      expect(find.text(l.cashProof('৳৩,০০০', '৳১,২০০')), findsOneWidget);
      expect(find.text(l.cashPending('৳৭০০')), findsOneWidget);
    });

    testWidgets('a failing section fails alone, with retry', (tester) async {
      await pumpDashboard(tester, failCash: true);
      expect(find.text(l.retry), findsOneWidget);
      expect(find.text(l.dashWhoOwes), findsOneWidget);
    });

    testWidgets('who owes: biggest due first; tap explains; see all', (
      tester,
    ) async {
      await pumpDashboard(tester);
      double y(String id) => tester.getTopLeft(find.byKey(ValueKey(id))).dy;
      expect(y('due-karim'), lessThan(y('due-selim')));
      expect(y('due-selim'), lessThan(y('due-rahim')));
      expect(find.text(l.dueRemindButton), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('due-karim')));
      await tester.pumpAndSettle();
      expect(find.text(l.balanceExplainTitle('Karim')), findsOneWidget);
      Navigator.of(
        tester.element(find.text(l.balanceExplainTitle('Karim'))),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text(l.dashSeeAll));
      await tester.pumpAndSettle();
      expect(find.text('money /money'), findsOneWidget);
    });

    testWidgets('no member sections, no old stat grid', (tester) async {
      await pumpDashboard(tester);
      expect(find.text(l.transTitle), findsNothing);
      expect(find.text(l.activityTitle), findsNothing);
      expect(find.text(l.dashMembers), findsNothing);
    });
  });

  group('member', () {
    testWidgets('transparency: everyone\'s deposits, own pocket, balance', (
      tester,
    ) async {
      await pumpDashboard(tester, manager: false);
      expect(find.text(l.transTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('trans-karim')), findsOneWidget);
      expect(find.byKey(const ValueKey('trans-rahim')), findsOneWidget);
      expect(
        find.text('${l.transDeposits} ৳২,০০০ · ${l.transOwnPocket} ৳৩০০'),
        findsOneWidget,
      );
      // No own-pocket part when there is none.
      expect(find.text('${l.transDeposits} ৳১,০০০'), findsOneWidget);
      expect(find.text('-৳৮৩৪.৬৩'), findsOneWidget);
      // Manager-only pieces stay out.
      expect(find.text(l.cashTitle), findsNothing);
      expect(find.text(l.dueRemindButton), findsNothing);
      expect(find.text(l.attnTitle), findsNothing);
    });

    testWidgets('transparency: dues first, me marked, left members only '
        'with activity', (tester) async {
      await pumpDashboard(
        tester,
        manager: false,
        members: [
          member('rahim', 'Rahim', role: MemberRole.manager),
          member('karim', 'Karim'),
          member('selim', 'Selim'),
          member('jubayer', 'Jubayer', status: MemberStatus.left),
          member('sumon', 'Sumon', status: MemberStatus.left),
        ],
        transparency: const [
          (
            memberId: 'rahim',
            displayName: 'Rahim',
            deposits: 1000.0,
            ownPocket: 0.0,
            closingBalance: 424.63,
          ),
          (
            memberId: 'jubayer',
            displayName: 'Jubayer',
            deposits: 0.0,
            ownPocket: 0.0,
            closingBalance: 0.0,
          ),
          (
            memberId: 'sumon',
            displayName: 'Sumon',
            deposits: 500.0,
            ownPocket: 0.0,
            closingBalance: 0.0,
          ),
          (
            memberId: 'selim',
            displayName: 'Selim',
            deposits: 0.0,
            ownPocket: 0.0,
            closingBalance: -100.0,
          ),
          (
            memberId: 'karim',
            displayName: 'Karim',
            deposits: 2000.0,
            ownPocket: 0.0,
            closingBalance: -834.63,
          ),
        ],
      );
      expect(find.byKey(const ValueKey('trans-jubayer')), findsNothing);
      double y(String id) =>
          tester.getTopLeft(find.byKey(ValueKey('trans-$id'))).dy;
      expect(y('karim'), lessThan(y('selim')));
      expect(y('selim'), lessThan(y('rahim')));
      expect(y('rahim'), lessThan(y('sumon')));
      Finder tag(String id, String s) => find.descendant(
        of: find.byKey(ValueKey('trans-$id')),
        matching: find.text(s),
      );
      expect(tag('karim', l.youTag), findsOneWidget);
      expect(tag('sumon', l.membersLeft), findsOneWidget);
      expect(find.text(l.youTag), findsOneWidget);
    });

    testWidgets('my activity: what changed, by whom; report a problem', (
      tester,
    ) async {
      await pumpDashboard(tester, manager: false);
      expect(find.text(l.activityTitle), findsOneWidget);
      final sentence = 'Rahim Karim-এর জমা ${l.auditVerified} ৳৫০০';
      expect(find.text(sentence), findsOneWidget);

      await tester.tap(find.text(l.reportProblem));
      await tester.pumpAndSettle();
      expect(find.text('new message'), findsOneWidget);
      expect(draft?.refType, 'deposit');
      expect(draft?.refId, 'd1');
      expect(draft?.refLabel, sentence);
    });

    testWidgets('my activity: empty state names what will show', (
      tester,
    ) async {
      await pumpDashboard(tester, manager: false, activity: const []);
      expect(find.text(l.activityEmpty), findsOneWidget);
    });
  });

  group('charts', () {
    testWidgets('spending: top four and the rest as others', (tester) async {
      await pumpDashboard(
        tester,
        categories: const [
          (category: 'বাজার', total: 1410.0, isBazar: true),
          (category: 'ভাড়া', total: 900.0, isBazar: false),
          (category: 'ওয়াইফাই', total: 500.0, isBazar: false),
          (category: 'গ্যাস', total: 300.0, isBazar: false),
          (category: 'বিদ্যুৎ', total: 200.0, isBazar: false),
          (category: 'পানি', total: 50.0, isBazar: false),
        ],
      );
      expect(find.text('গ্যাস'), findsOneWidget);
      expect(find.text('বিদ্যুৎ'), findsNothing);
      expect(find.text(l.dashOthers), findsOneWidget);
      expect(find.text('৳২৫০'), findsOneWidget);
    });

    testWidgets('trend: starts at the first month with data', (tester) async {
      await pumpDashboard(tester);
      expect(find.byType(LineChart), findsOneWidget);
      final summary = tester
          .getSemantics(
            find.bySemanticsLabel(RegExp('^${l.dashMonthlyTitle}: ')),
          )
          .label;
      // May, June, July had nothing: they are not plotted as zeros.
      expect(summary.split(', '), hasLength(3));
      expect(summary, isNot(contains('৳০')));
    });

    testWidgets('trend: hidden with fewer than two months of data', (
      tester,
    ) async {
      await pumpDashboard(tester, months: history(empty: 5));
      expect(find.byType(LineChart), findsNothing);
      expect(find.text(l.dashMonthlyTitle), findsNothing);
    });

    testWidgets('trend: short month labels, inside the chart', (tester) async {
      tester.view.physicalSize = const Size(360, 4000);
      await pumpDashboard(tester, locale: const Locale('en'));
      final chart = tester.getRect(find.byType(LineChart));
      for (final m in ['Aug', 'Sep', 'Oct']) {
        final label = tester.getRect(find.text(m));
        expect(label.left, greaterThanOrEqualTo(chart.left), reason: m);
        expect(label.right, lessThanOrEqualTo(chart.right), reason: m);
      }
      expect(find.text('October'), findsNothing);
    });

    testWidgets('dashboard_charts off hides spending and trend', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        extra: [
          flagsOff(['dashboard_charts']),
        ],
      );
      expect(find.text(l.dashCategoryTitle), findsNothing);
      expect(find.byType(LineChart), findsNothing);
    });
  });

  test('activeMonths drops only the leading empty months', () {
    final pts = history(empty: 2);
    expect(activeMonths(pts), hasLength(4));
    expect(activeMonths(pts).first.start, DateTime(2026, 7));
    expect(activeMonths(history(empty: 6)), isEmpty);
    expect(shortMonth(DateTime(2026, 10), 'en'), 'Oct');
    expect(shortMonth(DateTime(2026, 5), 'en'), 'May');
  });

  group('today empty states', () {
    testWidgets('only a truly empty mess says "no members"', (tester) async {
      final repo = MockMealRepository();
      when(() => repo.mealTypes(any())).thenAnswer(
        (_) async => [
          const MealType(
            id: 'lunch',
            messId: 'mess1',
            name: 'দুপুর',
            sortOrder: 1,
            weight: 1,
            enabled: true,
          ),
        ],
      );
      when(
        () => repo.entriesForDay(any(), any()),
      ).thenAnswer((_) async => const []);
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const TodayScreen())],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealRepositoryProvider.overrideWithValue(repo),
            ...overrides(
              members: [member('new', 'Nobin', status: MemberStatus.pending)],
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
      await tester.pumpAndSettle();
      expect(find.text(l.todayNoMembers), findsOneWidget);
      expect(find.byType(MonthDashboard), findsNothing);
      expect(find.byType(AppCard), findsWidgets);
    });
  });
}
