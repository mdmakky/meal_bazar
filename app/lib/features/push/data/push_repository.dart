import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors.dart';
import '../domain/push.dart';

class PushRepository {
  PushRepository(this._client);

  final SupabaseClient _client;

  /// Upsert; a token registered to another account moves to me.
  Future<void> registerToken(String token, String platform) => guard(
    () => _client.rpc<void>(
      'register_device_token',
      params: {'p_token': token, 'p_platform': platform},
    ),
  );

  Future<void> unregisterToken(String token) => guard(
    () => _client.rpc<void>(
      'unregister_device_token',
      params: {'p_token': token},
    ),
  );

  Future<NotificationPrefs> fetchPrefs() => guard(() async {
    final row = await _client
        .from('profiles')
        .select('notification_prefs')
        .eq('id', _uid())
        .single();
    return NotificationPrefs.fromJson(row['notification_prefs']);
  });

  Future<void> savePrefs(NotificationPrefs prefs) => guard(() async {
    requireRows(
      await _client
          .from('profiles')
          .update({'notification_prefs': prefs.raw})
          .eq('id', _uid())
          .select('id'),
    );
  });

  /// Manager: pushes each member who owes money their due; returns how many
  /// were notified. Throws `rateLimited` within 10 minutes of the last send.
  Future<int> sendDueReminders(String messId) => guard(() async {
    final n = await _client.rpc(
      'send_due_reminders',
      params: {'p_mess': messId},
    );
    return n as int;
  });

  String _uid() =>
      _client.auth.currentUser?.id ??
      (throw const AppFailure(FailureKind.notAuthenticated));
}
