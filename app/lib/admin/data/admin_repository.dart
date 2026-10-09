import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors.dart';
import '../domain/admin_models.dart';

/// Calls a Postgres function and returns its decoded result.
typedef Rpc = Future<dynamic> Function(String fn, Map<String, dynamic> params);

/// Thrown when AI_GATEWAY_URL is not set; the AI page explains the fix.
class GatewayNotConfigured implements Exception {
  const GatewayNotConfigured();
}

/// Every Super Admin call: admin RPCs, the `branding` bucket and the AI
/// gateway's admin endpoints. Each RPC re-checks `is_platform_admin()`.
class AdminRepository {
  AdminRepository({
    required Rpc rpc,
    this.client,
    http.Client? httpClient,
    this.gatewayUrl = '',
    String? Function()? token,
  }) : _rpc = rpc,
       _http = httpClient ?? http.Client(),
       _token = token ?? (() => null);

  factory AdminRepository.supabase(
    SupabaseClient client, {
    required String gatewayUrl,
  }) => AdminRepository(
    rpc: (fn, params) => client.rpc(fn, params: params),
    client: client,
    gatewayUrl: gatewayUrl,
    token: () => client.auth.currentSession?.accessToken,
  );

  final Rpc _rpc;
  final SupabaseClient? client;
  final http.Client _http;
  final String gatewayUrl;
  final String? Function() _token;

  Future<dynamic> _call(String fn, [Map<String, dynamic> params = const {}]) =>
      guard(() => _rpc(fn, params));

  /// A set-returning function gives a list; a jsonb one may give either.
  static List<Map<String, dynamic>> rows(dynamic result) => switch (result) {
    final List l => [for (final r in l) Map<String, dynamic>.from(r as Map)],
    final Map m => [Map<String, dynamic>.from(m)],
    _ => const [],
  };

  Future<bool> isPlatformAdmin() async =>
      (await _call('is_platform_admin')) == true;

  Future<AdminStats> stats() async {
    final r = rows(await _call('admin_stats'));
    return AdminStats.fromJson(r.isEmpty ? const {} : r.first);
  }

  Future<List<AiUsageRow>> aiUsage(int days) async => rows(
    await _call('admin_ai_usage', {'p_days': days}),
  ).map(AiUsageRow.fromJson).toList();

  Future<List<MessRow>> listMesses(
    String search,
    int limit,
    int offset,
  ) async => rows(
    await _call('admin_list_messes', {
      'p_search': search.trim().isEmpty ? null : search.trim(),
      'p_limit': limit,
      'p_offset': offset,
    }),
  ).map(MessRow.fromJson).toList();

  Future<List<UserRow>> listUsers(String search, int limit, int offset) async =>
      rows(
        await _call('admin_list_users', {
          'p_search': search.trim().isEmpty ? null : search.trim(),
          'p_limit': limit,
          'p_offset': offset,
        }),
      ).map(UserRow.fromJson).toList();

  Future<void> setMessSuspended(String messId, bool suspended, String reason) =>
      _call('admin_set_mess_suspended', {
        'p_mess': messId,
        'p_suspended': suspended,
        'p_reason': reason,
      });

  Future<void> setUserSuspended(String userId, bool suspended, String reason) =>
      _call('admin_set_user_suspended', {
        'p_user': userId,
        'p_suspended': suspended,
        'p_reason': reason,
      });

  Future<void> setAdmin(String email, bool isAdmin) => _call(
    'admin_set_admin',
    {'p_email': email.trim(), 'p_is_admin': isAdmin},
  );

  Future<List<DeletionRow>> deletionQueue() async => rows(
    await _call('admin_deletion_queue'),
  ).map(DeletionRow.fromJson).toList();

  /// `{key: value, …}` for every platform_config row.
  Future<Map<String, dynamic>> config() async {
    final r = rows(await _call('get_platform_config'));
    return r.isEmpty ? {} : r.first;
  }

  Future<void> setConfig(String key, Object value) =>
      _call('admin_set_config', {'p_key': key, 'p_value': value});

  Future<List<SecretRow>> listSecrets() async =>
      rows(await _call('admin_list_secrets')).map(SecretRow.fromJson).toList();

  /// Null or empty [value] deletes the secret.
  Future<void> setSecret(String name, String? value) =>
      _call('admin_set_secret', {'p_name': name, 'p_value': value});

  /// Uploads to the public `branding` bucket and returns the public URL.
  Future<String> uploadLogo(Uint8List bytes, String extension) =>
      guard(() async {
        final c = client!;
        final ext = extension.toLowerCase();
        // A fresh name per upload busts CDN and browser caches.
        final path = 'logo-${DateTime.now().millisecondsSinceEpoch}.$ext';
        await c.storage
            .from('branding')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: ext == 'svg' ? 'image/svg+xml' : 'image/$ext',
                upsert: true,
              ),
            );
        return c.storage.from('branding').getPublicUrl(path);
      });

  /// Browser redirect to Google; the session arrives on return.
  Future<void> signInWithGoogleWeb() => guard(
    () => client!.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: Uri.base.origin,
    ),
  );

  // ── AI gateway admin endpoints ─────────────────────────────────────────

  Uri _gateway(String path, [Map<String, String>? query]) {
    if (gatewayUrl.isEmpty) throw const GatewayNotConfigured();
    final base = gatewayUrl.endsWith('/')
        ? gatewayUrl.substring(0, gatewayUrl.length - 1)
        : gatewayUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Map<String, String> _headers() {
    final jwt = _token();
    if (jwt == null) throw const AppFailure(FailureKind.notAuthenticated);
    return {'Authorization': 'Bearer $jwt', 'Content-Type': 'application/json'};
  }

  Future<Object?> _decode(Future<http.Response> req) async {
    final res = await guard(() => req);
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw AppFailure(FailureKind.notManager, 'gateway ${res.statusCode}');
    }
    if (res.statusCode >= 400) {
      throw AppFailure(FailureKind.unknown, 'gateway ${res.statusCode}');
    }
    return jsonDecode(res.body);
  }

  /// [provider] is gemini, openrouter or all.
  Future<List<ModelInfo>> models(String provider) async {
    final uri = _gateway('/api/admin/models', {'provider': provider});
    final body = await _decode(_http.get(uri, headers: _headers()));
    final list = body is Map ? body['models'] ?? body['data'] : body;
    return rows(
      list is List ? list : const [],
    ).map(ModelInfo.fromJson).toList();
  }

  Future<ModelTestResult> testModel(
    String provider,
    String model,
    String kind,
  ) async {
    final uri = _gateway('/api/admin/test-model');
    final body = await _decode(
      _http.post(
        uri,
        headers: _headers(),
        body: jsonEncode({'provider': provider, 'model': model, 'kind': kind}),
      ),
    );
    return ModelTestResult.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : const {},
    );
  }
}
