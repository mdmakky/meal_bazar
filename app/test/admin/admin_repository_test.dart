import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meal_bazar/admin/data/admin_repository.dart';
import 'package:meal_bazar/admin/domain/admin_models.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A repository whose RPCs answer from [results]; records each call.
({AdminRepository repo, List<(String, Map<String, dynamic>)> calls}) fake(
  Map<String, dynamic> results, {
  http.Client? httpClient,
  String gatewayUrl = '',
}) {
  final calls = <(String, Map<String, dynamic>)>[];
  final repo = AdminRepository(
    rpc: (fn, params) async {
      calls.add((fn, params));
      final r = results[fn];
      if (r is Exception) throw r;
      return r;
    },
    httpClient: httpClient,
    gatewayUrl: gatewayUrl,
    token: () => 'jwt',
  );
  return (repo: repo, calls: calls);
}

void main() {
  test('is_platform_admin: only a literal true counts', () async {
    expect(
      await fake({'is_platform_admin': true}).repo.isPlatformAdmin(),
      isTrue,
    );
    expect(
      await fake({'is_platform_admin': false}).repo.isPlatformAdmin(),
      isFalse,
    );
    expect(
      await fake({'is_platform_admin': null}).repo.isPlatformAdmin(),
      isFalse,
    );
  });

  test('admin_stats parses jsonb, missing counters are 0', () async {
    final s = await fake({
      'admin_stats': {'users_total': 12, 'meals_7d': '40', 'extra': 1},
    }).repo.stats();
    expect(s['users_total'], 12);
    expect(s['meals_7d'], 40);
    expect(s['deletion_pending'], 0);
    expect(s.values.keys, AdminStats.keys);
  });

  test('admin_list_messes passes paging and parses rows', () async {
    final f = fake({
      'admin_list_messes': [
        {
          'id': 'm1',
          'name': 'Green House',
          'created_at': '2026-10-01T10:00:00Z',
          'member_count': 7,
          'manager_names': ['Rahim', 'Karim'],
          'last_activity': null,
          'suspended_at': '2026-10-05T00:00:00Z',
        },
      ],
    });
    final rows = await f.repo.listMesses('  green ', 25, 50);
    expect(f.calls.single.$1, 'admin_list_messes');
    expect(f.calls.single.$2, {
      'p_search': 'green',
      'p_limit': 25,
      'p_offset': 50,
    });
    final m = rows.single;
    expect(m.name, 'Green House');
    expect(m.memberCount, 7);
    expect(m.managerNames, 'Rahim, Karim');
    expect(m.lastActivity, isNull);
    expect(m.suspended, isTrue);
  });

  test('blank search is sent as null', () async {
    final f = fake({'admin_list_users': <Object>[]});
    await f.repo.listUsers('  ', 25, 0);
    expect(f.calls.single.$2['p_search'], isNull);
  });

  test('admin_list_users parses rows', () async {
    final rows = await fake({
      'admin_list_users': [
        {
          'id': 'u1',
          'email': 'a@b.co',
          'full_name': null,
          'created_at': '2026-09-01T00:00:00Z',
          'last_sign_in_at': '2026-10-08T00:00:00Z',
          'mess_count': 2,
          'suspended_at': null,
          'is_admin': true,
        },
      ],
    }).repo.listUsers('', 25, 0);
    final u = rows.single;
    expect(u.email, 'a@b.co');
    expect(u.fullName, '');
    expect(u.messCount, 2);
    expect(u.isAdmin, isTrue);
    expect(u.suspended, isFalse);
  });

  test('suspend / admin writes send the documented params', () async {
    final f = fake({});
    await f.repo.setMessSuspended('m1', true, 'spam');
    await f.repo.setUserSuspended('u1', false, '');
    await f.repo.setAdmin(' x@y.co ', true);
    await f.repo.setConfig('features', {'ai': false});
    await f.repo.setSecret('GEMINI_API_KEY', null);
    expect(f.calls.map((c) => c.$1), [
      'admin_set_mess_suspended',
      'admin_set_user_suspended',
      'admin_set_admin',
      'admin_set_config',
      'admin_set_secret',
    ]);
    expect(f.calls.map((c) => c.$2).toList(), [
      {'p_mess': 'm1', 'p_suspended': true, 'p_reason': 'spam'},
      {'p_user': 'u1', 'p_suspended': false, 'p_reason': ''},
      {'p_email': 'x@y.co', 'p_is_admin': true},
      {
        'p_key': 'features',
        'p_value': {'ai': false},
      },
      {'p_name': 'GEMINI_API_KEY', 'p_value': null},
    ]);
  });

  test('ai usage, deletion queue, secrets and config parse', () async {
    final f = fake({
      'admin_ai_usage': [
        {'day': '2026-10-01', 'feature': 'meal_draft', 'calls': 3},
        {'day': '2026-10-01', 'feature': 'bazar_draft', 'calls': 2},
        {'day': '2026-09-30', 'feature': 'meal_draft', 'calls': 1},
      ],
      'admin_deletion_queue': [
        {
          'user_id': 'u9',
          'requested_at': '2026-10-01T00:00:00Z',
          'processed_at': null,
          'last_error': 'boom',
        },
      ],
      'admin_list_secrets': [
        {
          'name': 'GEMINI_API_KEY',
          'last4': 'abcd',
          'updated_at': '2026-10-02T00:00:00Z',
          'updated_by': 'u1',
        },
      ],
      'get_platform_config': {
        'features': {'ai': true},
      },
    });
    final usage = await f.repo.aiUsage(30);
    expect(f.calls.single.$2, {'p_days': 30});
    expect(callsPerDay(usage).map((d) => d.calls), [1, 5]);
    final q = (await f.repo.deletionQueue()).single;
    expect(q.userId, 'u9');
    expect(q.lastError, 'boom');
    expect(q.processedAt, isNull);
    final s = (await f.repo.listSecrets()).single;
    expect(s.last4, 'abcd');
    expect(await f.repo.config(), {
      'features': {'ai': true},
    });
  });

  test('SQL errors become AppFailure with the key in the detail', () async {
    final f = fake({
      'admin_stats': const PostgrestException(
        message: 'NOT_PLATFORM_ADMIN',
        code: 'P0001',
      ),
    });
    await expectLater(
      f.repo.stats(),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.debugMessage,
          'debug',
          contains('NOT_PLATFORM_ADMIN'),
        ),
      ),
    );
  });

  group('gateway', () {
    test('no AI_GATEWAY_URL throws GatewayNotConfigured', () async {
      await expectLater(
        fake({}).repo.models('all'),
        throwsA(isA<GatewayNotConfigured>()),
      );
    });

    test('models sends the JWT and parses entries', () async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        return http.Response(
          jsonEncode([
            {
              'provider': 'openrouter',
              'id': 'x/paid',
              'name': 'Paid',
              'context_length': 128000,
              'input_price_per_mtok': 0.5,
              'output_price_per_mtok': 1.5,
              'free': false,
              'vision': true,
              'text': true,
            },
            {
              'provider': 'gemini',
              'id': 'gemini-flash-latest',
              'input_price_per_mtok': null,
              'free': true,
            },
          ]),
          200,
        );
      });
      final models = await fake(
        {},
        httpClient: client,
        gatewayUrl: 'https://gw.example/',
      ).repo.models('all');
      expect(
        seen.url.toString(),
        'https://gw.example/api/admin/models?provider=all',
      );
      expect(seen.headers['Authorization'], 'Bearer jwt');
      expect(models.first.paid, isTrue);
      expect(models.first.maxPrice, 1.5);
      expect(models.last.paid, isFalse);
      expect(models.last.inputPrice, isNull);
    });

    test('test-model posts the body and parses the result', () async {
      final client = MockClient((req) async {
        expect(jsonDecode(req.body), {
          'provider': 'gemini',
          'model': 'g',
          'kind': 'vision',
        });
        return http.Response(
          jsonEncode({
            'ok': true,
            'latency_ms': 812,
            'sample': 'hi',
            'error': null,
          }),
          200,
        );
      });
      final r = await fake(
        {},
        httpClient: client,
        gatewayUrl: 'https://gw',
      ).repo.testModel('gemini', 'g', 'vision');
      expect(r.ok, isTrue);
      expect(r.latencyMs, 812);
    });

    test('403 maps to a permission failure', () async {
      final client = MockClient((_) async => http.Response('no', 403));
      await expectLater(
        fake(
          {},
          httpClient: client,
          gatewayUrl: 'https://gw',
        ).repo.models('all'),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.notManager,
          ),
        ),
      );
    });
  });
}
