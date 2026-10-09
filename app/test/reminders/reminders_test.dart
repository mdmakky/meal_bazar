import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/l10n/gen/app_localizations.dart';
import 'package:meal_bazar/core/theme/app_theme.dart';
import 'package:meal_bazar/features/mess/application/mess_providers.dart';
import 'package:meal_bazar/features/reminders/application/reminder_service.dart';
import 'package:meal_bazar/features/reminders/domain/reminders.dart';
import 'package:meal_bazar/features/reminders/presentation/reminders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../platform/fixed_config.dart';

class Scheduled {
  Scheduled(this.id, this.at, this.route, this.daily, this.body);
  final int id;
  final tz.TZDateTime at;
  final String route;
  final bool daily;
  final String body;
}

class FakeNotifications implements LocalNotifications {
  final scheduled = <int, Scheduled>{};
  bool allowed = false;
  bool asked = false;

  @override
  void Function(String route) get onTap => (_) {};

  @override
  Future<void> init() async {}

  @override
  Future<void> schedule({
    required int id,
    required tz.TZDateTime at,
    required String title,
    required String body,
    required String route,
    required bool daily,
  }) async => scheduled[id] = Scheduled(id, at, route, daily, body);

  final shown = <({int id, String title, String body, String? route})>[];

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? route,
  }) async => shown.add((id: id, title: title, body: body, route: route));

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<void> cancelAll() async => scheduled.clear();

  @override
  Future<List<int>> pendingIds() async => scheduled.keys.toList();

  @override
  Future<bool> permitted() async => allowed;

  @override
  Future<bool> requestPermission() async {
    asked = true;
    return allowed = true;
  }
}

/// [h]:[m] Dhaka (UTC+6, no DST) as a UTC instant.
DateTime dhakaAt(int day, int h, [int m = 0]) =>
    DateTime.utc(2026, 10, day, h - 6, m);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('fire times', () {
    test('cutoff reminder is 30 min before the cutoff, in Dhaka', () {
      final at = nextCutoffReminder(dhakaAt(9, 10), '22:00:00');
      expect(at.location.name, 'Asia/Dhaka');
      expect([at.day, at.hour, at.minute], [9, 21, 30]);
      expect(at.toUtc(), DateTime.utc(2026, 10, 9, 15, 30));
    });

    test('rolls to tomorrow once today\'s time has passed', () {
      final at = nextCutoffReminder(dhakaAt(9, 21, 45), '22:00:00');
      expect([at.day, at.hour, at.minute], [10, 21, 30]);
    });

    test('wraps across midnight and falls back on garbage', () {
      final early = nextCutoffReminder(dhakaAt(9, 10), '00:15:00');
      expect([early.day, early.hour, early.minute], [9, 23, 45]);
      final bad = nextCutoffReminder(dhakaAt(9, 10), 'nope');
      expect([bad.hour, bad.minute], [21, 30]);
    });

    test('duty reminder is 20:00 the evening before', () {
      final at = dutyReminderAt(DateTime(2026, 11, 1));
      expect([at.month, at.day, at.hour], [10, 31, 20]);
      expect(dutyId(DateTime(2026, 11, 1)), 20261101);
      expect(isDutyId(dutyId(DateTime(2026, 11, 1))), isTrue);
    });

    test('toggles off → no schedule; members get no nudge', () {
      List<ReminderKind> plan(bool manager, ReminderSettings s) => [
        for (final r in planDaily(
          now: dhakaAt(9, 10),
          cutoff: '22:00:00',
          isManager: manager,
          settings: s,
        ))
          r.kind,
      ];
      const off = ReminderSettings(cutoff: false, nudge: false, duty: false);
      expect(plan(true, const ReminderSettings()), [
        ReminderKind.cutoff,
        ReminderKind.nudge,
      ]);
      expect(plan(false, const ReminderSettings()), [ReminderKind.cutoff]);
      expect(plan(true, off), isEmpty);
    });
  });

  group('ReminderService', () {
    late FakeNotifications fake;
    late ReminderService service;
    const manager = ReminderContext(
      cutoff: '22:00:00',
      isManager: true,
      locale: 'bn',
    );
    setUp(() {
      fake = FakeNotifications();
      service = ReminderService(fake, clock: () => dhakaAt(9, 10));
    });

    test('schedules daily reminders with routes', () async {
      await service.sync(manager, const ReminderSettings());
      final cutoff = fake.scheduled[ReminderKind.cutoff.id]!;
      expect(cutoff.daily, isTrue);
      expect(cutoff.route, '/today');
      expect(cutoff.body, 'কালকের মিল বন্ধ করতে চাইলে এখনই করুন');
      final nudge = fake.scheduled[ReminderKind.nudge.id]!;
      expect([nudge.at.hour, nudge.route], [21, '/meals']);
    });

    test('toggling off removes the reminder', () async {
      await service.sync(manager, const ReminderSettings());
      await service.sync(manager, const ReminderSettings(nudge: false));
      expect(fake.scheduled.keys, [ReminderKind.cutoff.id]);
    });

    test('no active mess → no daily reminders', () async {
      await service.sync(manager, const ReminderSettings());
      await service.sync(
        const ReminderContext(cutoff: null, isManager: false, locale: 'bn'),
        const ReminderSettings(),
      );
      expect(fake.scheduled, isEmpty);
    });

    test(
      'duty: scheduled the evening before, skipped when off or past',
      () async {
        await service.scheduleDutyReminder(DateTime(2026, 10, 12), 'Mess');
        final duty = fake.scheduled[20261012]!;
        expect([duty.at.day, duty.at.hour, duty.daily], [11, 20, false]);
        expect(duty.body, contains('Mess'));

        await service.scheduleDutyReminder(DateTime(2026, 10, 9), 'Mess');
        expect(fake.scheduled.containsKey(20261009), isFalse);

        await service.sync(manager, const ReminderSettings(duty: false));
        expect(fake.scheduled.containsKey(20261012), isFalse);
        await service.scheduleDutyReminder(DateTime(2026, 10, 13), 'Mess');
        expect(fake.scheduled.containsKey(20261013), isFalse);
      },
    );

    test('sign-out cancels everything', () async {
      await service.sync(manager, const ReminderSettings());
      await service.scheduleDutyReminder(DateTime(2026, 10, 12), 'Mess');
      await service.sync(null, const ReminderSettings());
      expect(fake.scheduled, isEmpty);
    });
  });

  group('RemindersScreen', () {
    Future<FakeNotifications> pump(WidgetTester tester, bool manager) async {
      final fake = FakeNotifications();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localNotificationsProvider.overrideWithValue(fake),
            amIManagerProvider.overrideWithValue(manager),
            platformConfig({}),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('bn'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RemindersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('toggles persist locally', (tester) async {
      SharedPreferences.setMockInitialValues({'remind.duty': false});
      await pump(tester, true);
      expect(find.byType(SwitchListTile), findsNWidgets(3));
      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect([for (final s in switches) s.value], [true, true, false]);

      await tester.tap(find.text('মিল বন্ধের সময়ের আগে'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('remind.cutoff'), isFalse);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
        isFalse,
      );
    });

    testWidgets('members do not see the manager nudge', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pump(tester, false);
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      expect(find.text('রাতে মিল বসানোর কথা'), findsNothing);
    });

    testWidgets('links to push settings', (tester) async {
      await pump(tester, false);
      expect(find.text('নোটিফিকেশন'), findsOneWidget);
    });

    testWidgets('permission off shows a request button', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final fake = await pump(tester, true);
      expect(find.text('নোটিফিকেশন বন্ধ আছে'), findsOneWidget);
      await tester.tap(find.text('চালু করুন'));
      await tester.pumpAndSettle();
      expect(fake.asked, isTrue);
      expect(find.text('নোটিফিকেশন বন্ধ আছে'), findsNothing);
    });
  });
}
