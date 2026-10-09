import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_config.dart';
import '../../../core/router.dart';
import '../../../core/supabase.dart';
import '../../auth/application/auth_providers.dart';
import '../../reminders/application/reminder_service.dart';
import '../data/push_repository.dart';
import '../domain/push.dart';

/// Thin wrapper over Firebase so tests can swap in a fake. Firebase starts
/// lazily; without `google-services.json` [init] answers false and push
/// stays off for this run.
class PushMessaging {
  Future<bool>? _ready;

  Future<bool> init() => _ready ??= () async {
    if (kIsWeb) return false;
    try {
      await Firebase.initializeApp();
      return true;
    } catch (e) {
      debugPrint('push: Firebase not configured ($e)');
      return false;
    }
  }();

  Future<String?> token() => FirebaseMessaging.instance.getToken();

  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  /// Pushes that arrive while the app is in the foreground.
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Taps on a push while the app was in the background.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// The push whose tap cold-started the app, if any.
  Future<RemoteMessage?> initialMessage() =>
      FirebaseMessaging.instance.getInitialMessage();
}

class PushService {
  PushService({
    required this.messaging,
    required this.repo,
    required this.notifications,
    required this.navigate,
    this.onArrive,
  });

  final PushMessaging messaging;
  final PushRepository repo;
  final LocalNotifications notifications;
  final void Function(String route) navigate;

  /// The route of each push that arrives while the app is open, so an open
  /// screen (a message thread) can refresh itself.
  final void Function(String route)? onArrive;

  bool _signedIn = false;
  bool _wired = false;

  /// Registered for the signed-in user; what sign-out removes.
  String? _token;

  static String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// Registers this device for the signed-in user. Best-effort.
  Future<void> sync({required bool signedIn, required bool enabled}) async {
    _signedIn = signedIn && enabled;
    if (!_signedIn || !await messaging.init()) return;
    await _wire();
    final token = await messaging.token();
    if (token != null) await _register(token);
  }

  Future<void> _register(String token) async {
    if (!_signedIn) return;
    await repo.registerToken(token, _platform);
    _token = token;
  }

  /// Listeners, once per app run.
  Future<void> _wire() async {
    if (_wired) return;
    _wired = true;
    messaging.onTokenRefresh.listen(
      (t) => _register(t).catchError((Object e) => debugPrint('push: $e')),
    );
    messaging.onMessage.listen((m) async {
      final route = pushRoute(m.data);
      if (route != null) onArrive?.call(route);
      final n = m.notification;
      if (n == null) return;
      try {
        await notifications.init();
        await notifications.show(
          // Below the duty-reminder ids (yyyymmdd), above the daily ones.
          id: 1000 + DateTime.now().millisecondsSinceEpoch % 1000000,
          title: n.title ?? '',
          body: n.body ?? '',
          route: route,
        );
      } catch (e) {
        debugPrint('push: $e');
      }
    });
    messaging.onMessageOpenedApp.listen(_open);
    final initial = await messaging.initialMessage();
    if (initial != null) _open(initial);
  }

  void _open(RemoteMessage m) {
    final route = pushRoute(m.data);
    if (route != null) navigate(route);
  }

  /// Removes this device from my account, before the session is cleared.
  /// Never throws and never holds sign-out up for long (offline).
  Future<void> unregister() async {
    _signedIn = false;
    try {
      final token =
          _token ?? (await messaging.init() ? await messaging.token() : null);
      _token = null;
      if (token != null) {
        await repo.unregisterToken(token).timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('push unregister: $e');
    }
  }
}

// ── Providers ────────────────────────────────────────────────────────────

final pushRepositoryProvider = Provider<PushRepository>(
  (ref) => PushRepository(ref.watch(supabaseClientProvider)),
);

final pushMessagingProvider = Provider<PushMessaging>((ref) => PushMessaging());

// Typed explicitly: auth → push → router → auth is a cycle for inference.
final Provider<PushService> pushServiceProvider = Provider<PushService>(
  (ref) => PushService(
    messaging: ref.watch(pushMessagingProvider),
    repo: ref.watch(pushRepositoryProvider),
    notifications: ref.watch(localNotificationsProvider),
    navigate: (route) => ref.read(routerProvider).go(route),
    onArrive: ref.watch(pushArrivalsProvider).add,
  ),
);

/// Routes of pushes received while the app is open (see [PushService.onArrive]).
final pushArrivalsProvider = Provider<StreamController<String>>((ref) {
  final c = StreamController<String>.broadcast();
  ref.onDispose(c.close);
  return c;
});

/// The latest arrival; watch or listen to refresh on a push.
final pushArrivalProvider = StreamProvider<String>(
  (ref) => ref.watch(pushArrivalsProvider).stream,
);

/// Registers the device on sign-in (and token refresh) while the platform
/// `push` flag is on. Watched once from the app root; Firebase starts after
/// the first frame so a cold start stays fast.
final pushSyncProvider = Provider<void>((ref) {
  final auth = ref.watch(authStateProvider);
  final enabled = ref.watch(
    platformConfigProvider.select((c) => c.feature('push')),
  );
  if (!auth.hasValue) return;
  final signedIn = auth.value != null;
  final service = ref.watch(pushServiceProvider);
  unawaited(() async {
    try {
      await SchedulerBinding.instance.endOfFrame;
      await service.sync(signedIn: signedIn, enabled: enabled);
    } catch (e) {
      debugPrint('push: $e');
    }
  }());
});

/// Asks for the notification permission (Android 13+ / iOS). Called after
/// creating or joining a mess and from the settings screen, never on launch.
Future<void> askNotificationPermission(Ref ref) async {
  if (!ref.read(platformConfigProvider).feature('push')) return;
  try {
    final n = ref.read(localNotificationsProvider);
    await n.init();
    if (!await n.permitted()) await n.requestPermission();
    ref.invalidate(notificationPermissionProvider);
  } catch (e) {
    debugPrint('push permission: $e');
  }
}

/// My per-type switches (`profiles.notification_prefs`).
final notificationPrefsProvider =
    AsyncNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
      NotificationPrefsNotifier.new,
    );

class NotificationPrefsNotifier extends AsyncNotifier<NotificationPrefs> {
  @override
  Future<NotificationPrefs> build() async {
    final uid = await ref.watch(authStateProvider.future);
    if (uid == null) return const NotificationPrefs();
    return ref.watch(pushRepositoryProvider).fetchPrefs();
  }

  /// Optimistic; rolls back and rethrows (AppFailure) when the save fails.
  Future<void> set(PushType type, bool on) async {
    final before = state.value ?? const NotificationPrefs();
    final after = before.toggled(type, on);
    state = AsyncData(after);
    try {
      await ref.read(pushRepositoryProvider).savePrefs(after);
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }
}
