import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/dates.dart';
import '../../../core/env.dart';
import '../../../core/errors.dart';
import '../../../core/supabase.dart';
import '../domain/ai_draft.dart';

final aiClientProvider = Provider<AiClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return AiClient(
    client,
    baseUrl: Env.aiGatewayUrl,
    token: () =>
        ref.read(supabaseClientProvider).auth.currentSession?.accessToken,
  );
});

/// Calls the Vercel AI gateway. Throws [AiUnavailable] when AI is off, over
/// quota or down, and [AppFailure] for everything else.
class AiClient {
  AiClient(
    this._http, {
    required this.baseUrl,
    required this.token,
    this.timeout = const Duration(seconds: 25),
  });

  final http.Client _http;
  final String baseUrl;
  final String? Function() token;
  final Duration timeout;

  Future<MealDraft> mealDraft({
    required String messId,
    required DateTime date,
    required String text,
  }) async => MealDraft.fromJson(
    await _post('meal-draft', {
      'mess_id': messId,
      'date': isoDate(date),
      'text': text,
    }),
  );

  /// [imageBase64] must be a JPEG (the gateway checks the magic bytes).
  Future<BazarDraft> bazarDraft({
    required String messId,
    required DateTime date,
    required String imageBase64,
  }) async => BazarDraft.fromJson(
    await _post('bazar-draft', {
      'mess_id': messId,
      'date': isoDate(date),
      'image_base64': imageBase64,
    }),
  );

  Future<Map<String, dynamic>> _post(
    String feature,
    Map<String, Object> body,
  ) async {
    if (baseUrl.isEmpty) throw const AiUnavailable('disabled');
    final jwt = token();
    if (jwt == null) {
      throw const AppFailure(FailureKind.notAuthenticated, 'no session');
    }
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final res = await guard(
      () => _http
          .post(
            Uri.parse('$base/api/ai/$feature'),
            headers: {
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout),
    );
    final debug = '$feature ${res.statusCode}';
    switch (res.statusCode) {
      case 200:
        break;
      case 401:
        throw AppFailure(FailureKind.notAuthenticated, debug);
      case 403:
        throw AppFailure(FailureKind.notManager, debug);
      case 400 || 413:
        throw AppFailure(FailureKind.validation, debug);
      default:
        throw AppFailure(FailureKind.unknown, debug);
    }
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      throw AppFailure(FailureKind.unknown, '$debug: $e');
    }
    if (json['unavailable'] == true) {
      throw AiUnavailable('${json['reason'] ?? 'providers'}');
    }
    final draft = json['draft'];
    if (draft is! Map<String, dynamic>) {
      throw AppFailure(FailureKind.unknown, '$debug: no draft');
    }
    return draft;
  }
}
