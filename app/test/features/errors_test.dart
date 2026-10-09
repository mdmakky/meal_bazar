import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meal_bazar/core/errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

FailureKind kindOf(Object e) => mapError(e).kind;

void main() {
  test('maps SQL fail() keys', () {
    const cases = {
      'NOT_AUTHENTICATED': FailureKind.notAuthenticated,
      'NOT_MANAGER': FailureKind.notManager,
      'INVALID_INVITE': FailureKind.invalidInvite,
      'ALREADY_MEMBER': FailureKind.alreadyMember,
      'LAST_MANAGER': FailureKind.lastManager,
      'MONTH_CLOSED': FailureKind.monthClosed,
      'PREVIOUS_MONTH_OPEN': FailureKind.previousMonthOpen,
      'LATER_MONTH_CLOSED': FailureKind.laterMonthClosed,
      'CUTOFF_PASSED': FailureKind.cutoffPassed,
      'MONTH_NOT_ENDED': FailureKind.monthNotEnded,
      'MISSING_MEALS': FailureKind.missingMeals,
      'AUTO_MEALS_PENDING': FailureKind.autoMealsPending,
      'REASON_REQUIRED': FailureKind.validation,
      'USER_LINK_FORBIDDEN': FailureKind.unknown,
    };
    cases.forEach((key, kind) {
      expect(
        kindOf(PostgrestException(message: key, code: 'P0001')),
        kind,
        reason: key,
      );
    });
  });

  test('maps Postgres codes', () {
    expect(
      kindOf(
        const PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ),
      ),
      FailureKind.notManager,
    );
    expect(
      kindOf(const PostgrestException(message: 'check', code: '23514')),
      FailureKind.validation,
    );
    expect(
      kindOf(
        const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
      ),
      FailureKind.notAuthenticated,
    );
  });

  test('maps auth errors', () {
    expect(
      kindOf(
        const AuthApiException(
          'Token has expired or is invalid',
          statusCode: '403',
          code: 'otp_expired',
        ),
      ),
      FailureKind.invalidOtp,
    );
    expect(
      kindOf(
        const AuthApiException(
          'Too many requests',
          statusCode: '429',
          code: 'over_sms_send_rate_limit',
        ),
      ),
      FailureKind.rateLimited,
    );
    expect(
      kindOf(AuthRetryableFetchException(message: 'offline')),
      FailureKind.network,
    );
    expect(kindOf(const AuthException('weird')), FailureKind.unknown);
  });

  test('maps email auth errors', () {
    const cases = {
      'invalid_credentials': FailureKind.invalidCredentials,
      'user_already_exists': FailureKind.emailTaken,
      'email_exists': FailureKind.emailTaken,
      'weak_password': FailureKind.weakPassword,
      'email_not_confirmed': FailureKind.emailNotConfirmed,
    };
    cases.forEach((code, kind) {
      expect(
        kindOf(AuthApiException('x', statusCode: '400', code: code)),
        kind,
        reason: code,
      );
    });
    expect(
      kindOf(
        AuthWeakPasswordException(
          message: 'weak',
          statusCode: '422',
          reasons: const ['length'],
        ),
      ),
      FailureKind.weakPassword,
    );
  });

  test('maps network errors', () {
    expect(kindOf(const SocketException('no route')), FailureKind.network);
    expect(kindOf(TimeoutException('slow')), FailureKind.network);
  });

  test('passes AppFailure through and falls back to unknown', () {
    const f = AppFailure(FailureKind.lastManager);
    expect(mapError(f), same(f));
    expect(kindOf(StateError('x')), FailureKind.unknown);
  });

  test('requireRows: 0 rows affected means RLS refused → notManager', () {
    expect(
      () => requireRows([]),
      throwsA(
        isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.notManager),
      ),
    );
    final rows = [
      {'id': 'a'},
    ];
    expect(requireRows(rows), same(rows));
  });

  test('guard rethrows as AppFailure', () async {
    await expectLater(
      guard<void>(
        () async => throw const PostgrestException(
          message: 'LAST_MANAGER',
          code: 'P0001',
        ),
      ),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.kind,
          'kind',
          FailureKind.lastManager,
        ),
      ),
    );
  });
}
