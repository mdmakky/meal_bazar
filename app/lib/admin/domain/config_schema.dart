import 'dart:convert';

import 'package:flutter/painting.dart';

/// platform_config defaults and editor rules (docs/platform-admin.md).
/// Editors start from `withDefaults(key, server value)` so a missing field
/// never leaves a control blank.

/// A deep, mutable copy of JSON data.
dynamic deepCopy(Object? v) => jsonDecode(jsonEncode(v));

typedef FlagInfo = ({String key, String bn, String en});
typedef FlagGroup = ({String bn, String en, List<FlagInfo> flags});

const featureGroups = <FlagGroup>[
  (
    bn: 'মিল',
    en: 'Meals',
    flags: [
      (
        key: 'member_meal_off',
        bn: 'সদস্য নিজে মিল বন্ধ করতে পারে',
        en: 'Members turn their own meals off',
      ),
      (key: 'guest_meals', bn: 'অতিথির মিল', en: 'Guest meals'),
      (
        key: 'meal_defaults',
        bn: 'সদস্যদের ডিফল্ট মিল',
        en: 'Member default meals',
      ),
      (key: 'fixed_rate', bn: 'নির্দিষ্ট মিল রেট', en: 'Fixed meal rate'),
      (key: 'cook_share', bn: 'বুয়ার খরচ ভাগ', en: 'Cook cost share'),
    ],
  ),
  (
    bn: 'টাকা',
    en: 'Money',
    flags: [
      (
        key: 'member_deposits',
        bn: 'সদস্য নিজে জমা দেখাতে পারে',
        en: 'Members submit deposits',
      ),
      (
        key: 'deposit_verification',
        bn: 'জমা যাচাই (ম্যানেজার)',
        en: 'Manager verifies deposits',
      ),
      (key: 'receipts', bn: 'রসিদের ছবি', en: 'Receipt photos'),
      (key: 'split', bn: 'খরচ ভাগের নিয়ম', en: 'Expense split rules'),
      (
        key: 'recurring',
        bn: 'মাসিক নিয়মিত বিল',
        en: 'Monthly recurring bills',
      ),
      (key: 'share_bills', bn: 'বিল শেয়ার', en: 'Share bills'),
      (key: 'due_reminders', bn: 'বাকির রিমাইন্ডার', en: 'Due reminders'),
    ],
  ),
  (
    bn: 'বাজার',
    en: 'Bazar',
    flags: [
      (
        key: 'bazar_picker',
        bn: 'বাজারের জিনিস বাছাই তালিকা',
        en: 'Bazar item picker',
      ),
      (key: 'duty', bn: 'বাজার ডিউটি রোস্টার', en: 'Bazar duty roster'),
    ],
  ),
  (
    bn: 'এআই',
    en: 'AI',
    flags: [
      (key: 'ai', bn: 'সব এআই ফিচার', en: 'All AI features'),
      (
        key: 'ai_meal_draft',
        bn: 'লেখা থেকে মিলের খসড়া',
        en: 'Meal drafts from text',
      ),
      (
        key: 'ai_bazar_scan',
        bn: 'রসিদ স্ক্যান করে বাজারের খসড়া',
        en: 'Bazar drafts from receipt scans',
      ),
    ],
  ),
  (
    bn: 'যোগাযোগ',
    en: 'Communication',
    flags: [
      (key: 'notices', bn: 'নোটিশ বোর্ড', en: 'Notice board'),
      (
        key: 'messages',
        bn: 'ম্যানেজারকে বার্তা ও সমস্যা জানানো',
        en: 'Member–manager messages',
      ),
      (
        key: 'reminders',
        bn: 'রিমাইন্ডার নোটিফিকেশন',
        en: 'Reminder notifications',
      ),
      (key: 'invite_qr', bn: 'কিউআর কোডে আমন্ত্রণ', en: 'QR code invites'),
      (key: 'push', bn: 'পুশ নোটিফিকেশন', en: 'Push notifications'),
    ],
  ),
  (
    bn: 'অ্যাকাউন্ট ও লগইন',
    en: 'Account and login',
    flags: [
      (key: 'google_login', bn: 'গুগল দিয়ে লগইন', en: 'Google sign-in'),
      (key: 'email_login', bn: 'ইমেইল দিয়ে লগইন', en: 'Email sign-in'),
    ],
  ),
  (
    bn: 'অন্যান্য',
    en: 'Other',
    flags: [
      (key: 'export', bn: 'ডেটা এক্সপোর্ট', en: 'Data export'),
      (key: 'pdf_report', bn: 'পিডিএফ রিপোর্ট', en: 'PDF report'),
      (key: 'dashboard_charts', bn: 'ড্যাশবোর্ড চার্ট', en: 'Dashboard charts'),
      (key: 'audit_log', bn: 'অডিট লগ', en: 'Audit log'),
      (key: 'offline_mode', bn: 'অফলাইন মোড', en: 'Offline mode'),
      (key: 'setup_checklist', bn: 'শুরুর চেকলিস্ট', en: 'Setup checklist'),
    ],
  ),
];

List<String> get allFlags => [
  for (final g in featureGroups)
    for (final f in g.flags) f.key,
];

const aiProviders = ['gemini', 'openrouter'];
const maxChain = 5;
const bannerLevels = ['info', 'warning', 'critical'];
const splitMethods = ['equal', 'meal'];

final Map<String, Object> _defaults = {
  'ai': {
    'enabled': true,
    'text_chain': [
      {'provider': 'gemini', 'model': 'gemini-flash-latest'},
      {'provider': 'openrouter', 'model': 'openrouter/free'},
    ],
    'vision_chain': [
      {'provider': 'gemini', 'model': 'gemini-flash-latest'},
      {'provider': 'openrouter', 'model': 'openrouter/free'},
    ],
    'quota_meal_draft': 30,
    'quota_bazar_draft': 10,
    'timeout_ms': 20000,
    'temperature': 0.2,
    'allow_paid': false,
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
    'banner': {'active': false, 'text_bn': '', 'text_en': '', 'level': 'info'},
  },
  'defaults': {
    'month_start_day': 1,
    'meal_off_cutoff': '22:00',
    'meal_types': <Object>[],
    'expense_categories': <Object>[],
  },
  'catalogue': {'groups': <Object>[]},
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

const paymentMethodKeys = ['cash', 'bkash', 'nagad', 'bank', 'other'];

/// The editable value for [key]: server data over defaults, deep-copied.
dynamic withDefaults(String key, Object? server) {
  switch (key) {
    case 'features':
      final m = server is Map ? Map<String, dynamic>.from(server) : {};
      // Missing = true; unknown keys are kept as they are.
      return <String, dynamic>{
        ...m,
        for (final f in allFlags) f: m[f] is bool ? m[f] : true,
      };
    case 'payment_methods':
      final list = server is List ? server : const [];
      Map? find(String k) =>
          list.whereType<Map>().where((m) => m['key'] == k).firstOrNull;
      return [
        for (final k in paymentMethodKeys)
          {
            'key': k,
            'label_bn': '${find(k)?['label_bn'] ?? k}',
            'label_en': '${find(k)?['label_en'] ?? k}',
            'enabled': find(k)?['enabled'] ?? true,
          },
      ];
    case 'ai':
      final m = server is Map ? Map<String, dynamic>.from(server) : null;
      final out = deepCopy(_defaults['ai']) as Map<String, dynamic>;
      if (m == null) return out;
      out.addAll(deepCopy(m) as Map<String, dynamic>);
      // v1 flat fields: build the chains from them when chains are absent.
      if (m['text_chain'] is! List && m['primary_model'] is String) {
        final chain = [
          _entryFor(m['primary_model'] as String),
          if (m['fallback_model'] is String)
            _entryFor(m['fallback_model'] as String),
        ];
        out['text_chain'] = chain;
        if (m['vision_chain'] is! List) out['vision_chain'] = deepCopy(chain);
      }
      out.remove('primary_model');
      out.remove('fallback_model');
      return out;
    default:
      final d = _defaults[key];
      if (d is Map) {
        final out = deepCopy(d) as Map<String, dynamic>;
        if (server is Map) {
          for (final e in server.entries) {
            // Nested maps (the banner) merge one level deeper.
            out[e.key as String] = e.value is Map && out[e.key] is Map
                ? {...out[e.key] as Map, ...e.value as Map}
                : deepCopy(e.value);
          }
        }
        return out;
      }
      return deepCopy(server);
  }
}

Map<String, dynamic> _entryFor(String model) => {
  'provider': model.startsWith('openrouter') || model.contains('/')
      ? 'openrouter'
      : 'gemini',
  'model': model,
};

// ── Validation ───────────────────────────────────────────────────────────

enum Invalid { required, number, range, version, email, url, time, hex }

Invalid? requiredText(String? v) =>
    (v ?? '').trim().isEmpty ? Invalid.required : null;

Invalid? intInRange(String? v, int min, int max) {
  final n = int.tryParse((v ?? '').trim());
  if (n == null) return Invalid.number;
  return n < min || n > max ? Invalid.range : null;
}

Invalid? positiveNumber(String? v, {double max = 100}) {
  final n = double.tryParse((v ?? '').trim());
  if (n == null) return Invalid.number;
  return n <= 0 || n > max ? Invalid.range : null;
}

final _version = RegExp(r'^\d+\.\d+\.\d+$');
Invalid? version(String? v) =>
    _version.hasMatch((v ?? '').trim()) ? null : Invalid.version;

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
Invalid? optionalEmail(String? v) {
  final s = (v ?? '').trim();
  return s.isEmpty || _email.hasMatch(s) ? null : Invalid.email;
}

Invalid? optionalUrl(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return null;
  final u = Uri.tryParse(s);
  return u != null &&
          (u.scheme == 'https' || u.scheme == 'http') &&
          u.hasAuthority
      ? null
      : Invalid.url;
}

final _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
Invalid? time(String? v) =>
    _time.hasMatch((v ?? '').trim()) ? null : Invalid.time;

final _hex = RegExp(r'^#[0-9A-Fa-f]{6}$');
Invalid? hexColor(String? v) =>
    _hex.hasMatch((v ?? '').trim()) ? null : Invalid.hex;

/// Parses `#RRGGBB`; null when invalid.
Color? parseHex(String? v) => hexColor(v) == null
    ? Color(int.parse('FF${v!.trim().substring(1)}', radix: 16))
    : null;

/// WCAG 2.x contrast ratio, 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// WCAG minimum for non-text marks like the accent (dots, washes, outlines).
const minAccentContrast = 3.0;
