import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:meal_bazar/features/ai/data/ai_client.dart';
import 'package:meal_bazar/features/ai/domain/ai_draft.dart';

void main() {
  late http.Request sent;

  AiClient client(
    FutureOr<http.Response> Function() reply, {
    String baseUrl = 'https://ai.example/',
    String? token = 'jwt',
    Duration timeout = const Duration(seconds: 25),
  }) => AiClient(
    MockClient((req) async {
      sent = req;
      return reply();
    }),
    baseUrl: baseUrl,
    token: () => token,
    timeout: timeout,
  );

  http.Response ok(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<MealDraft> meal(AiClient c) =>
      c.mealDraft(messId: 'm1', date: DateTime(2026, 10, 8), text: 'রহিম ২');

  test('parses a meal draft and sends bearer + body', () async {
    final d = await meal(
      client(
        () => ok({
          'draft': {
            'entries': [
              {
                'member_id': 'r',
                'meal_type_id': 't',
                'count': 2,
                'guest_count': 1,
                'is_off': false,
              },
            ],
            'unmatched': ['রাতে গেস্ট ১ — কার?'],
            'confidence': 0.8,
          },
        }),
      ),
    );
    expect(sent.url.toString(), 'https://ai.example/api/ai/meal-draft');
    expect(sent.headers['Authorization'], 'Bearer jwt');
    expect(jsonDecode(sent.body), {
      'mess_id': 'm1',
      'date': '2026-10-08',
      'text': 'রহিম ২',
    });
    final e = d.entries.single;
    expect((e.memberId, e.count, e.guestCount, e.isOff), ('r', 2.0, 1, false));
    expect(d.unmatched, ['রাতে গেস্ট ১ — কার?']);
    expect(d.confidence, 0.8);
  });

  test('parses a bazar draft', () async {
    final d =
        await client(
          () => ok({
            'draft': {
              'items': [
                {'name': 'আলু', 'qty': 2, 'unit': 'kg', 'price': 60},
                {'name': 'ডাল', 'qty': null, 'unit': null, 'price': 55.5},
              ],
              'total': 120,
              'total_matches_items': false,
              'notes': '',
            },
          }),
        ).bazarDraft(
          messId: 'm1',
          date: DateTime(2026, 10, 8),
          imageBase64: '/9j/AA',
        );
    expect(sent.url.path, '/api/ai/bazar-draft');
    expect(d.items.map((i) => i.price), [60, 55.5]);
    expect(d.items.last.qty, isNull);
    expect((d.total, d.totalMatchesItems), (120.0, false));
  });

  test('unavailable maps to AiUnavailable(reason)', () async {
    for (final reason in ['disabled', 'quota', 'providers']) {
      await expectLater(
        meal(client(() => ok({'unavailable': true, 'reason': reason}))),
        throwsA(isA<AiUnavailable>().having((e) => e.reason, 'reason', reason)),
      );
    }
  });

  test('no gateway URL = disabled, without a request', () async {
    var called = false;
    final c = AiClient(
      MockClient((_) async {
        called = true;
        return http.Response('', 200);
      }),
      baseUrl: '',
      token: () => 'jwt',
    );
    await expectLater(
      meal(c),
      throwsA(isA<AiUnavailable>().having((e) => e.reason, 'r', 'disabled')),
    );
    expect(called, isFalse);
  });

  Matcher failure(FailureKind k) =>
      throwsA(isA<AppFailure>().having((e) => e.kind, 'kind', k));

  test('HTTP errors map to AppFailure', () async {
    final cases = {
      401: FailureKind.notAuthenticated,
      403: FailureKind.notManager,
      413: FailureKind.validation,
      500: FailureKind.unknown,
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      await expectLater(
        meal(client(() => ok({'error': 'x'}, key))),
        failure(value),
      );
    }
  });

  test('no session = notAuthenticated', () async {
    await expectLater(
      meal(client(() => ok({}), token: null)),
      failure(FailureKind.notAuthenticated),
    );
  });

  test('timeout and socket errors map to network', () async {
    await expectLater(
      meal(
        client(
          () => Completer<http.Response>().future,
          timeout: const Duration(milliseconds: 10),
        ),
      ),
      failure(FailureKind.network),
    );
    await expectLater(
      meal(client(() => throw http.ClientException('offline'))),
      failure(FailureKind.network),
    );
  });
}
