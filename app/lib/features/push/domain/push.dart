/// Push types the server sends (supabase/migrations/0019_push.sql,
/// `message` from 0022_messages.sql). [key] is
/// the `push_outbox.type` and the `profiles.notification_prefs` key.
enum PushType {
  joinRequest('join_request', managerOnly: true),
  depositPending('deposit_pending', managerOnly: true),
  depositVerified('deposit_verified'),
  depositRejected('deposit_rejected'),
  notice('notice'),
  bazarAdded('bazar_added'),
  expenseAdded('expense_added'),
  monthClosed('month_closed'),
  dueReminder('due_reminder'),
  message('message');

  const PushType(this.key, {this.managerOnly = false});

  final String key;

  /// Only managers receive it, so only they see its switch.
  final bool managerOnly;
}

/// `profiles.notification_prefs`: a type is on unless it is explicitly false.
class NotificationPrefs {
  const NotificationPrefs([this.raw = const {}]);

  factory NotificationPrefs.fromJson(Object? json) =>
      NotificationPrefs(json is Map ? json.cast<String, Object?>() : const {});

  /// Kept whole on save, so keys this version doesn't know survive.
  final Map<String, Object?> raw;

  bool isOn(PushType t) => raw[t.key] != false;

  NotificationPrefs toggled(PushType t, bool on) =>
      NotificationPrefs({...raw, t.key: on});
}

/// The in-app route of a push's data payload, or null.
String? pushRoute(Map<String, dynamic> data) {
  final r = data['route'];
  return r is String && r.startsWith('/') ? r : null;
}
