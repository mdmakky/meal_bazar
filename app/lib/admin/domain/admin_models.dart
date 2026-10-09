/// Rows returned by the admin RPCs (docs/platform-admin.md). Parsing is
/// lenient: a missing or null field becomes a zero/empty value, never a crash.
library;

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
double? _double(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v');
String _str(Object? v) => v == null ? '' : '$v';

class AdminStats {
  const AdminStats(this.values);

  /// The documented counters, in display order.
  static const keys = [
    'users_total',
    'users_7d',
    'messes_total',
    'messes_active_7d',
    'meals_7d',
    'bazars_7d',
    'ai_calls_7d',
    'suspended_messes',
    'deletion_pending',
  ];

  factory AdminStats.fromJson(Map<String, dynamic> j) =>
      AdminStats({for (final k in keys) k: _int(j[k])});

  final Map<String, int> values;

  int operator [](String key) => values[key] ?? 0;
}

class MessRow {
  const MessRow({
    required this.id,
    required this.name,
    this.createdAt,
    this.memberCount = 0,
    this.managerNames = '',
    this.lastActivity,
    this.suspendedAt,
  });

  factory MessRow.fromJson(Map<String, dynamic> j) {
    final managers = j['manager_names'];
    return MessRow(
      id: _str(j['id']),
      name: _str(j['name']),
      createdAt: _date(j['created_at']),
      memberCount: _int(j['member_count']),
      // text or text[] depending on the SQL; show both the same way.
      managerNames: managers is List ? managers.join(', ') : _str(managers),
      lastActivity: _date(j['last_activity']),
      suspendedAt: _date(j['suspended_at']),
    );
  }

  final String id;
  final String name;
  final DateTime? createdAt;
  final int memberCount;
  final String managerNames;
  final DateTime? lastActivity;
  final DateTime? suspendedAt;

  bool get suspended => suspendedAt != null;
}

class UserRow {
  const UserRow({
    required this.id,
    required this.email,
    this.fullName = '',
    this.createdAt,
    this.lastSignInAt,
    this.messCount = 0,
    this.suspendedAt,
    this.isAdmin = false,
  });

  factory UserRow.fromJson(Map<String, dynamic> j) => UserRow(
    id: _str(j['id']),
    email: _str(j['email']),
    fullName: _str(j['full_name']),
    createdAt: _date(j['created_at']),
    lastSignInAt: _date(j['last_sign_in_at']),
    messCount: _int(j['mess_count']),
    suspendedAt: _date(j['suspended_at']),
    isAdmin: j['is_admin'] == true,
  );

  final String id;
  final String email;
  final String fullName;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;
  final int messCount;
  final DateTime? suspendedAt;
  final bool isAdmin;

  bool get suspended => suspendedAt != null;
}

class AiUsageRow {
  const AiUsageRow({required this.day, required this.feature, this.calls = 0});

  factory AiUsageRow.fromJson(Map<String, dynamic> j) => AiUsageRow(
    day: _date(j['day']) ?? DateTime(1970),
    feature: _str(j['feature']),
    calls: _int(j['calls']),
  );

  final DateTime day;
  final String feature;
  final int calls;
}

/// Calls per day, all features summed, oldest first.
List<({DateTime day, int calls})> callsPerDay(List<AiUsageRow> rows) {
  final byDay = <DateTime, int>{};
  for (final r in rows) {
    final d = DateTime(r.day.year, r.day.month, r.day.day);
    byDay[d] = (byDay[d] ?? 0) + r.calls;
  }
  final days = byDay.keys.toList()..sort();
  return [for (final d in days) (day: d, calls: byDay[d]!)];
}

class DeletionRow {
  const DeletionRow({
    required this.userId,
    this.requestedAt,
    this.processedAt,
    this.lastError,
  });

  factory DeletionRow.fromJson(Map<String, dynamic> j) => DeletionRow(
    userId: _str(j['user_id']),
    requestedAt: _date(j['requested_at']),
    processedAt: _date(j['processed_at']),
    lastError: j['last_error'] == null ? null : '${j['last_error']}',
  );

  final String userId;
  final DateTime? requestedAt;
  final DateTime? processedAt;
  final String? lastError;
}

/// Allowed credential names, checked again by `admin_set_secret`.
const secretNames = [
  'GEMINI_API_KEY',
  'OPENROUTER_API_KEY',
  'SMS_PROVIDER_KEY',
  'SMTP_PASSWORD',
  'PUSH_GATEWAY_URL',
  'PUSH_DISPATCH_SECRET',
];

/// A stored credential. Never carries the value, only its last 4 chars.
class SecretRow {
  const SecretRow({required this.name, this.last4 = '', this.updatedAt});

  factory SecretRow.fromJson(Map<String, dynamic> j) => SecretRow(
    name: _str(j['name']),
    last4: _str(j['last4']),
    updatedAt: _date(j['updated_at']),
  );

  final String name;
  final String last4;
  final DateTime? updatedAt;
}

/// An entry of the gateway's `/api/admin/models` list.
class ModelInfo {
  const ModelInfo({
    required this.provider,
    required this.id,
    this.name = '',
    this.description = '',
    this.contextLength = 0,
    this.inputPrice,
    this.outputPrice,
    this.free = false,
    this.vision = false,
    this.text = true,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> j) => ModelInfo(
    provider: _str(j['provider']),
    id: _str(j['id']),
    name: _str(j['name']),
    description: _str(j['description']),
    contextLength: _int(j['context_length']),
    inputPrice: _double(j['input_price_per_mtok']),
    outputPrice: _double(j['output_price_per_mtok']),
    free: j['free'] == true,
    vision: j['vision'] == true,
    text: j['text'] != false,
  );

  final String provider;
  final String id;
  final String name;
  final String description;
  final int contextLength;

  /// USD per million tokens; null = unknown (Gemini).
  final double? inputPrice;
  final double? outputPrice;
  final bool free;
  final bool vision;
  final bool text;

  String get label => name.isEmpty ? id : name;

  /// Known to cost money. Unknown prices (Gemini free tier) are not paid.
  bool get paid => (inputPrice ?? 0) > 0 || (outputPrice ?? 0) > 0;

  /// The larger of the two prices, for the max-price filter and sorting.
  double get maxPrice =>
      [inputPrice ?? 0, outputPrice ?? 0].reduce((a, b) => a > b ? a : b);
}

class ModelTestResult {
  const ModelTestResult({
    required this.ok,
    this.latencyMs = 0,
    this.sample = '',
    this.error,
  });

  factory ModelTestResult.fromJson(Map<String, dynamic> j) => ModelTestResult(
    ok: j['ok'] == true,
    latencyMs: _int(j['latency_ms']),
    sample: _str(j['sample']),
    error: j['error'] == null ? null : '${j['error']}',
  );

  final bool ok;
  final int latencyMs;
  final String sample;
  final String? error;
}

enum ModelSort { name, provider, context, inputPrice, outputPrice }

/// The AI page's catalogue filters. Free and Paid together (or neither)
/// show both; Vision/Text require that capability.
typedef ModelFilter = ({
  String provider, // all, gemini, openrouter
  String search,
  bool free,
  bool paid,
  bool vision,
  bool text,
  int minContext,
  double? maxPrice, // USD per 1M tokens, either direction
  ModelSort sort,
  bool ascending,
});

const ModelFilter defaultModelFilter = (
  provider: 'all',
  search: '',
  free: false,
  paid: false,
  vision: false,
  text: false,
  minContext: 0,
  maxPrice: null,
  sort: ModelSort.name,
  ascending: true,
);

List<ModelInfo> filterModels(List<ModelInfo> all, ModelFilter f) {
  final q = f.search.trim().toLowerCase();
  final out = all.where((m) {
    if (f.provider != 'all' && m.provider != f.provider) return false;
    if (q.isNotEmpty &&
        !m.id.toLowerCase().contains(q) &&
        !m.name.toLowerCase().contains(q)) {
      return false;
    }
    if (f.free != f.paid && (f.free ? !m.free : m.free)) return false;
    if (f.vision && !m.vision) return false;
    if (f.text && !m.text) return false;
    if (m.contextLength < f.minContext) return false;
    if (f.maxPrice != null && m.maxPrice > f.maxPrice!) return false;
    return true;
  }).toList();
  int cmp(ModelInfo a, ModelInfo b) => switch (f.sort) {
    ModelSort.name => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    ModelSort.provider => a.provider.compareTo(b.provider),
    ModelSort.context => a.contextLength.compareTo(b.contextLength),
    ModelSort.inputPrice => (a.inputPrice ?? 0).compareTo(b.inputPrice ?? 0),
    ModelSort.outputPrice => (a.outputPrice ?? 0).compareTo(b.outputPrice ?? 0),
  };
  out.sort((a, b) => f.ascending ? cmp(a, b) : cmp(b, a));
  return out;
}

/// Chain entries (`provider/model`) the catalogue knows to be paid.
List<String> paidChainEntries(Map ai, List<ModelInfo> catalogue) {
  final paid = {
    for (final m in catalogue)
      if (m.paid) '${m.provider}/${m.id}',
  };
  return {
    for (final chain in [ai['text_chain'], ai['vision_chain']])
      if (chain is List)
        for (final e in chain.whereType<Map>())
          if (paid.contains('${e['provider']}/${e['model']}'))
            '${e['provider']}/${e['model']}',
  }.toList();
}
