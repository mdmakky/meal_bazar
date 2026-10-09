/// Push types the server sends (supabase/migrations/0019_push.sql,
/// `message` from 0022_messages.sql, deposit_added / bazar_request* from
/// 0026). [key] is
/// the `push_outbox.type` and the `profiles.notification_prefs` key.
enum PushType {
  joinRequest('join_request', managerOnly: true),
  depositPending('deposit_pending', managerOnly: true),
  depositVerified('deposit_verified'),
  depositRejected('deposit_rejected'),
  depositAdded('deposit_added'),
  notice('notice'),
  bazarAdded('bazar_added'),
  bazarRequest('bazar_request', managerOnly: true),
  bazarRequestReviewed('bazar_request_reviewed'),
  dutyToday('duty_today'),
  expenseAdded('expense_added'),
  monthClosed('month_closed'),
  dueReminder('due_reminder'),
  message('message'),
  groupMessage('group_message');

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
String? pushRoute(Map<String, dynamic> data) =>
    routeFor(data['type'] as String?, data['route']);

/// [route] for a notification of [type], sharpened where the server's is a
/// tab root: deposit pushes open the Deposits tab, where verify lives.
String? routeFor(String? type, Object? route) {
  if (route is! String || !route.startsWith('/')) return null;
  if (route == '/money' && (type?.startsWith('deposit_') ?? false)) {
    return '/money?tab=deposit';
  }
  return route;
}

/// One row of my `notifications` inbox (0026).
class InboxItem {
  const InboxItem({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.body = '',
    this.route,
    this.isRead = false,
  });

  factory InboxItem.fromJson(Map<String, dynamic> json) => InboxItem(
    id: (json['id'] as num).toInt(),
    type: json['type'] as String,
    title: json['title'] as String,
    body: json['body'] as String? ?? '',
    route: json['route'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    isRead: json['read_at'] != null,
  );

  final int id;
  final String type;
  final String title;
  final String body;

  /// In-app route to open on tap; only used when it starts with '/'.
  final String? route;
  final DateTime createdAt;
  final bool isRead;

  PushType? get pushType =>
      PushType.values.where((t) => t.key == type).firstOrNull;

  InboxItem read() => InboxItem(
    id: id,
    type: type,
    title: title,
    body: body,
    route: route,
    createdAt: createdAt,
    isRead: true,
  );
}

/// [items] (newest first) split into local calendar days, newest day first.
List<(DateTime, List<InboxItem>)> inboxByDay(List<InboxItem> items) {
  final out = <(DateTime, List<InboxItem>)>[];
  for (final i in items) {
    final d = DateTime(i.createdAt.year, i.createdAt.month, i.createdAt.day);
    if (out.isEmpty || out.last.$1 != d) out.add((d, []));
    out.last.$2.add(i);
  }
  return out;
}
