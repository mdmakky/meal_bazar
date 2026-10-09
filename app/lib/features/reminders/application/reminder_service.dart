import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/router.dart';
import '../../auth/application/auth_providers.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../domain/reminders.dart';

/// Thin wrapper over the plugin so tests can swap in a fake.
class LocalNotifications {
  LocalNotifications({required this.onTap});

  /// Gets the payload route of a tapped notification, including the tap
  /// that cold-launched the app.
  final void Function(String route) onTap;

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Idempotent.
  Future<void> init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload != null) onTap(r.payload!);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final route = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) && route != null) {
      onTap(route);
    }
  }();

  Future<void> schedule({
    required int id,
    required tz.TZDateTime at,
    required String title,
    required String body,
    required String route,
    required bool daily,
  }) => _plugin.zonedSchedule(
    id: id,
    scheduledDate: at,
    title: title,
    body: body,
    payload: route,
    notificationDetails: _details,
    // Inexact: no SCHEDULE_EXACT_ALARM (Play policy); a few minutes late is fine.
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: daily ? DateTimeComponents.time : null,
  );

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<List<int>> pendingIds() async => [
    for (final r in await _plugin.pendingNotificationRequests()) r.id,
  ];

  Future<bool> permitted() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return (await ios?.checkPermissions())?.isEnabled ?? false;
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }
}

/// What the reminders depend on. Null [cutoff] = no active mess.
class ReminderContext {
  const ReminderContext({
    required this.cutoff,
    required this.isManager,
    required this.locale,
  });

  final String? cutoff;
  final bool isManager;
  final String locale;
}

class ReminderService {
  ReminderService(this._n, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LocalNotifications _n;
  final DateTime Function() _clock;

  /// Last synced; used by [scheduleDutyReminder].
  ReminderSettings _settings = const ReminderSettings();
  String _locale = 'bn';

  /// Replaces the daily reminders and drops duty ones if turned off. Null
  /// [ctx] (signed out) cancels everything.
  Future<void> sync(ReminderContext? ctx, ReminderSettings settings) => _queue =
      _queue.catchError((Object _) {}).then((_) => _sync(ctx, settings));

  /// Runs syncs one at a time so a quick change of mess can't interleave.
  Future<void> _queue = Future.value();

  Future<void> _sync(ReminderContext? ctx, ReminderSettings settings) async {
    if (ctx == null) return _n.cancelAll();
    _settings = settings;
    _locale = ctx.locale;
    await _n.cancel(ReminderKind.cutoff.id);
    await _n.cancel(ReminderKind.nudge.id);
    if (!settings.duty) {
      for (final id in await _n.pendingIds()) {
        if (isDutyId(id)) await _n.cancel(id);
      }
    }
    final cutoffTime = ctx.cutoff;
    if (cutoffTime == null) return;
    final l = lookupAppLocalizations(Locale(ctx.locale));
    final plan = planDaily(
      now: _clock(),
      cutoff: cutoffTime,
      isManager: ctx.isManager,
      settings: settings,
    );
    for (final r in plan) {
      final cutoff = r.kind == ReminderKind.cutoff;
      await _n.schedule(
        id: r.kind.id,
        at: r.at,
        title: cutoff ? l.remindCutoffTitle : l.remindNudgeTitle,
        body: cutoff ? l.remindCutoffBody : l.remindNudgeBody,
        route: r.kind.route,
        daily: true,
      );
    }
  }

  /// For the bazar-duty feature: 20:00 the evening before [date]. Does
  /// nothing if that time has passed or the user turned duty reminders off.
  Future<void> scheduleDutyReminder(DateTime date, String messName) async {
    final at = dutyReminderAt(date);
    if (!_settings.duty || !at.isAfter(_clock())) return;
    final l = lookupAppLocalizations(Locale(_locale));
    await _n.schedule(
      id: dutyId(date),
      at: at,
      title: l.remindDutyTitle,
      body: l.remindDutyBody(messName),
      route: ReminderKind.duty.route,
      daily: false,
    );
  }
}

// ── Providers ────────────────────────────────────────────────────────────

final localNotificationsProvider = Provider<LocalNotifications>(
  (ref) =>
      LocalNotifications(onTap: (route) => ref.read(routerProvider).go(route)),
);

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(ref.watch(localNotificationsProvider)),
);

/// Toggles persisted on this device.
final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );

class ReminderSettingsNotifier extends AsyncNotifier<ReminderSettings> {
  static String _key(ReminderKind k) => 'remind.${k.name}';

  @override
  Future<ReminderSettings> build() async {
    final p = await SharedPreferences.getInstance();
    var s = const ReminderSettings();
    for (final k in ReminderKind.values) {
      s = s.toggled(k, p.getBool(_key(k)) ?? true);
    }
    return s;
  }

  Future<void> set(ReminderKind k, bool on) async {
    final current = state.value ?? const ReminderSettings();
    state = AsyncData(current.toggled(k, on));
    await (await SharedPreferences.getInstance()).setBool(_key(k), on);
  }
}

/// Notification permission; invalidate after asking.
final notificationPermissionProvider = FutureProvider<bool>(
  (ref) => ref.watch(localNotificationsProvider).permitted(),
);

/// Keeps scheduled reminders in step with sign-in, the current mess, my role
/// and the toggles. Watched once from the app root.
final reminderSyncProvider = Provider<void>((ref) {
  final auth = ref.watch(authStateProvider);
  final memberships = ref.watch(myMembershipsProvider);
  final membership = ref.watch(currentMembershipProvider);
  final locale = ref.watch(myProfileProvider.select((p) => p.value?.locale));
  final settings = ref.watch(reminderSettingsProvider).value;
  // Wait for real answers: a loading state must not cancel anything.
  if (!auth.hasValue || settings == null) return;
  final signedIn = auth.value != null;
  if (signedIn && !memberships.hasValue) return;
  final mess = membership?.mess;
  final active = membership?.member.status == MemberStatus.active;
  // Turned off platform-wide: null cancels everything already scheduled.
  final enabled = ref.watch(
    platformConfigProvider.select((c) => c.feature('reminders')),
  );
  final ctx = signedIn && enabled
      ? ReminderContext(
          cutoff: active ? mess?.mealOffCutoff : null,
          isManager: membership?.member.isActiveManager ?? false,
          locale: locale ?? 'bn',
        )
      : null;
  final n = ref.watch(localNotificationsProvider);
  final service = ref.watch(reminderServiceProvider);
  unawaited(() async {
    try {
      // Let the frame this change triggers (Home, on a cold start) render
      // first: time zone parsing + plugin init hold the UI isolate ~0.5-1.5 s.
      await SchedulerBinding.instance.endOfFrame;
      await n.init();
      await service.sync(ctx, settings);
    } catch (e) {
      // Reminders are best-effort; never break the app over them.
      debugPrint('reminders: $e');
    }
  }());
});
