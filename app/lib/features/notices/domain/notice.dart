/// One row of the `announcement_feed` view (a live, undeleted notice).
class Notice {
  const Notice({
    required this.id,
    required this.messId,
    required this.title,
    required this.createdAt,
    this.body = '',
    this.pinned = false,
    this.expiresAt,
    this.isRead = false,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    title: json['title'] as String,
    body: json['body'] as String? ?? '',
    pinned: json['pinned'] as bool? ?? false,
    expiresAt: json['expires_at'] == null
        ? null
        : DateTime.parse(json['expires_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    isRead: json['is_read'] as bool? ?? false,
  );

  final String id;
  final String messId;
  final String title;
  final String body;
  final bool pinned;
  final DateTime? expiresAt;
  final DateTime createdAt;

  /// Read by the signed-in user.
  final bool isRead;

  bool expiredAt(DateTime now) => expiresAt != null && !expiresAt!.isAfter(now);

  Notice copyWith({bool? isRead}) => Notice(
    id: id,
    messId: messId,
    title: title,
    body: body,
    pinned: pinned,
    expiresAt: expiresAt,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}

const noticeTitleMax = 80;
const noticeBodyMax = 1000;

/// Drops notices expired by [now]; pinned first, then newest first.
List<Notice> visibleNotices(Iterable<Notice> all, DateTime now) =>
    all.where((n) => !n.expiredAt(now)).toList()..sort(
      (a, b) => a.pinned != b.pinned
          ? (a.pinned ? -1 : 1)
          : b.createdAt.compareTo(a.createdAt),
    );
