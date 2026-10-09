import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/money/domain/bazar_catalogue.dart';
import '../supabase.dart';
import '../version.dart';

/// Seeded values of docs/platform-admin.md. Used for any key the server (or
/// the cache) lacks, so the app works before the SQL is deployed.
/// `features` is absent on purpose: a missing flag counts as true.
/// `catalogue` and `payment_methods` fall back to the built-in catalogue and
/// the ARB labels; `defaults` only seeds new messes on the server.
const platformDefaults = <String, Map<String, Object?>>{
  'ai': {
    'enabled': true,
    'primary_model': 'gemini-flash-latest',
    'fallback_model': 'openrouter/free',
    'quota_meal_draft': 30,
    'quota_bazar_draft': 10,
  },
  'app': {
    'maintenance': false,
    'maintenance_message_bn': '',
    'maintenance_message_en': '',
    'min_version': '1.0.0',
    'latest_version': '1.0.0',
    'update_message_bn': '',
    'update_message_en': '',
    'support_email': '',
    'support_whatsapp': '',
    'privacy_url': '',
  },
  'banner': {'active': false, 'text_bn': '', 'text_en': '', 'level': 'info'},
  'branding': {
    'app_name_bn': 'মিল বাজার',
    'app_name_en': 'Meal Bazar',
    'tagline_bn': 'মেসের পুরো হিসাব, ফোন থেকেই',
    'tagline_en': 'Your whole mess, from your phone',
    'logo_url': null,
    'accent_light': '#C98A0B',
    'accent_dark': '#E8B33A',
  },
};

enum BannerLevel { info, warning, critical }

/// Typed, defensive view of `get_platform_config()`. Every accessor falls
/// back to [platformDefaults] when a key is missing or has the wrong type.
@immutable
class PlatformConfig {
  const PlatformConfig([this.raw = const {}]);

  factory PlatformConfig.fromJson(Object? json) =>
      PlatformConfig(json is Map ? json.cast<String, Object?>() : const {});

  final Map<String, Object?> raw;

  static Map<String, Object?> _asMap(Object? v) =>
      v is Map ? v.cast<String, Object?>() : const {};

  Map<String, Object?> _section(String k) =>
      k == 'banner' ? _asMap(_section('app')['banner']) : _asMap(raw[k]);

  T _get<T>(String section, String key) {
    final v = _section(section)[key];
    return v is T ? v : platformDefaults[section]![key] as T;
  }

  static String _lang(String l) => l == 'en' ? 'en' : 'bn';

  // ── Feature flags ────────────────────────────────────────────────────────

  /// Only an explicit `false` turns a feature off.
  bool feature(String key) => _section('features')[key] != false;

  bool get aiOn => feature('ai') && _get<bool>('ai', 'enabled');
  bool get aiMealDraft => aiOn && feature('ai_meal_draft');
  bool get aiBazarScan => aiOn && feature('ai_bazar_scan');

  // ── App ──────────────────────────────────────────────────────────────────

  bool get maintenance => _get<bool>('app', 'maintenance');
  String maintenanceMessage(String lang) =>
      _get<String>('app', 'maintenance_message_${_lang(lang)}').trim();

  String get minVersion => _get<String>('app', 'min_version');
  bool needsUpdate([String current = appVersion]) =>
      compareVersions(current, minVersion) < 0;
  String updateMessage(String lang) =>
      _get<String>('app', 'update_message_${_lang(lang)}').trim();

  String get supportEmail => _get<String>('app', 'support_email').trim();
  String get supportWhatsapp => _get<String>('app', 'support_whatsapp').trim();
  String get privacyUrl => _get<String>('app', 'privacy_url').trim();

  bool get bannerActive => _get<bool>('banner', 'active');
  String bannerText(String lang) =>
      _get<String>('banner', 'text_${_lang(lang)}').trim();
  BannerLevel get bannerLevel =>
      BannerLevel.values.asNameMap()[_get<String>('banner', 'level')] ??
      BannerLevel.info;

  // ── Branding ─────────────────────────────────────────────────────────────

  String appName(String lang) =>
      _nonEmpty('branding', 'app_name_${_lang(lang)}');
  String tagline(String lang) =>
      _nonEmpty('branding', 'tagline_${_lang(lang)}');

  String? get logoUrl {
    final v = _section('branding')['logo_url'];
    return v is String && v.trim().startsWith('http') ? v.trim() : null;
  }

  Color get accentLight => _color('accent_light');
  Color get accentDark => _color('accent_dark');

  String _nonEmpty(String section, String key) {
    final v = _get<String>(section, key).trim();
    return v.isEmpty ? platformDefaults[section]![key]! as String : v;
  }

  static final _hex = RegExp(r'^#[0-9a-fA-F]{6}$');

  Color _color(String key) {
    final v = _get<String>('branding', key).trim();
    final hex = _hex.hasMatch(v)
        ? v
        : platformDefaults['branding']![key]! as String;
    return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
  }

  // ── Catalogue and payment methods ────────────────────────────────────────

  /// The bazar picker groups, or null for the built-in catalogue.
  List<CatalogueGroup>? get catalogue {
    final groups = _section('catalogue')['groups'];
    if (groups is! List) return null;
    final out = <CatalogueGroup>[
      for (final g in groups.map(_asMap))
        if (g['name'] case final String name when name.trim().isNotEmpty)
          (
            name: name.trim(),
            items: [
              for (final i in g['items'] is List ? g['items']! as List : [])
                if (_asMap(i)['name'] case final String n
                    when n.trim().isNotEmpty)
                  (
                    name: n.trim(),
                    unit: switch (_asMap(i)['unit']) {
                      final String u => u.trim(),
                      _ => '',
                    },
                  ),
            ],
          ),
    ];
    out.removeWhere((g) => g.items.isEmpty);
    return out.isEmpty ? null : out;
  }

  Map<String, Object?>? _method(String key) {
    final list = raw['payment_methods'];
    if (list is! List) return null;
    return list.map(_asMap).where((m) => m['key'] == key).firstOrNull;
  }

  /// The admin's label for a `pay_method` key, or null for the ARB label.
  String? methodLabel(String key, String lang) {
    final v = _method(key)?['label_${_lang(lang)}'];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  bool methodEnabled(String key) => _method(key)?['enabled'] != false;
}

// ── Provider ───────────────────────────────────────────────────────────────

/// Calls `get_platform_config()`. Overridden in tests.
final platformConfigFetchProvider = Provider<Future<Object?> Function()>(
  (ref) =>
      () async =>
          await ref.read(supabaseClientProvider).rpc('get_platform_config'),
);

/// Starts at [platformDefaults], swaps in the cached copy as soon as it is
/// read, then refreshes from the server in the background (and on resume,
/// at most every [PlatformConfigNotifier.minInterval]). Never blocks a frame.
final platformConfigProvider =
    NotifierProvider<PlatformConfigNotifier, PlatformConfig>(
      PlatformConfigNotifier.new,
    );

class PlatformConfigNotifier extends Notifier<PlatformConfig> {
  static const cacheKey = 'platform_config';
  static const minInterval = Duration(minutes: 5);

  DateTime? _fetchedAt;

  @override
  PlatformConfig build() {
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(listener.dispose);
    unawaited(_start());
    return const PlatformConfig();
  }

  Future<void> _start() async {
    try {
      final cached = (await SharedPreferences.getInstance()).getString(
        cacheKey,
      );
      // A server answer that already arrived wins over the cache.
      if (cached != null && _fetchedAt == null && ref.mounted) {
        state = PlatformConfig.fromJson(jsonDecode(cached));
      }
    } catch (e) {
      debugPrint('platform config cache: $e');
    }
    await refresh();
  }

  /// Fetches unless the last success is under [minInterval] old.
  Future<void> refresh({bool force = false}) async {
    final last = _fetchedAt;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < minInterval) {
      return;
    }
    try {
      final json = await ref.read(platformConfigFetchProvider)();
      if (json is! Map || !ref.mounted) return;
      _fetchedAt = DateTime.now();
      state = PlatformConfig.fromJson(json);
      await (await SharedPreferences.getInstance()).setString(
        cacheKey,
        jsonEncode(json),
      );
    } catch (e) {
      // Offline or not deployed yet: keep what we have.
      debugPrint('platform config: $e');
    }
  }
}

extension PlatformFeatureRef on WidgetRef {
  /// Rebuilds only when this flag changes.
  bool featureOn(String key) =>
      watch(platformConfigProvider.select((c) => c.feature(key)));
}
