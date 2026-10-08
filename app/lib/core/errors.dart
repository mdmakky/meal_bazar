import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// What went wrong, independent of language. The UI maps it to bn/en text.
enum FailureKind {
  network,
  notAuthenticated,
  notManager,
  invalidInvite,
  alreadyMember,
  lastManager,
  monthClosed,
  previousMonthOpen,
  laterMonthClosed,
  cutoffPassed,
  invalidOtp,
  rateLimited,
  validation,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure(this.kind, [this.debugMessage]);

  final FailureKind kind;
  final String? debugMessage;

  @override
  String toString() => 'AppFailure($kind, $debugMessage)';
}

/// SQL `fail()` keys raised as P0001 (see supabase/migrations).
const _sqlKeys = {
  'NOT_AUTHENTICATED': FailureKind.notAuthenticated,
  'NOT_MANAGER': FailureKind.notManager,
  // Not an active member of this mess: same "no permission" message.
  'NOT_MEMBER': FailureKind.notManager,
  'INVALID_INVITE': FailureKind.invalidInvite,
  'ALREADY_MEMBER': FailureKind.alreadyMember,
  'LAST_MANAGER': FailureKind.lastManager,
  'MONTH_CLOSED': FailureKind.monthClosed,
  'PREVIOUS_MONTH_OPEN': FailureKind.previousMonthOpen,
  'LATER_MONTH_CLOSED': FailureKind.laterMonthClosed,
  'CUTOFF_PASSED': FailureKind.cutoffPassed,
  'MEAL_TYPE_INVALID': FailureKind.validation,
  'REASON_REQUIRED': FailureKind.validation,
  'DEPOSIT_NOT_PENDING': FailureKind.validation,
  'RECEIPT_PATH_INVALID': FailureKind.validation,
};

AppFailure mapError(Object error) {
  if (error is AppFailure) return error;
  if (error is PostgrestException) return _fromPostgrest(error);
  if (error is AuthException) return _fromAuth(error);
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      // ponytail: package:http is not a direct dependency, so match by name.
      error.runtimeType.toString() == 'ClientException') {
    return AppFailure(FailureKind.network, '$error');
  }
  return AppFailure(FailureKind.unknown, '$error');
}

AppFailure _fromPostgrest(PostgrestException e) {
  final debug = '${e.code}: ${e.message}';
  final key = _sqlKeys[e.message.trim()];
  if (key != null) return AppFailure(key, debug);
  return switch (e.code) {
    // insufficient_privilege: RLS refused an insert/delete.
    '42501' => AppFailure(FailureKind.notManager, debug),
    // check / not-null / invalid input / unique violations.
    '23514' ||
    '23502' ||
    '22P02' ||
    '23505' => AppFailure(FailureKind.validation, debug),
    // JWT missing or expired.
    'PGRST301' || 'PGRST302' => AppFailure(FailureKind.notAuthenticated, debug),
    _ => AppFailure(FailureKind.unknown, debug),
  };
}

AppFailure _fromAuth(AuthException e) {
  final debug = '${e.statusCode}/${e.code}: ${e.message}';
  if (e is AuthRetryableFetchException) {
    return AppFailure(FailureKind.network, debug);
  }
  if (e is AuthSessionMissingException) {
    return AppFailure(FailureKind.notAuthenticated, debug);
  }
  final code = e.code ?? '';
  if (e.statusCode == '429' || code.startsWith('over_')) {
    return AppFailure(FailureKind.rateLimited, debug);
  }
  if (code == 'otp_expired' ||
      (e.statusCode == '403' && e.message.toLowerCase().contains('token'))) {
    return AppFailure(FailureKind.invalidOtp, debug);
  }
  if (code == 'validation_failed') {
    return AppFailure(FailureKind.validation, debug);
  }
  return AppFailure(FailureKind.unknown, debug);
}

/// Runs a data call and rethrows any error as an [AppFailure].
Future<T> guard<T>(Future<T> Function() run) async {
  try {
    return await run();
  } catch (e, st) {
    Error.throwWithStackTrace(mapError(e), st);
  }
}

/// RLS turns a forbidden update/delete into "0 rows affected" instead of an
/// error. Call on the `.select()` result of a mutation to surface that.
List<Map<String, dynamic>> requireRows(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) {
    throw const AppFailure(FailureKind.notManager, '0 rows affected');
  }
  return rows;
}
