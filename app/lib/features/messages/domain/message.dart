/// One row of the `message_thread_feed` view (supabase 0022).
class MessageThread {
  const MessageThread({
    required this.id,
    required this.messId,
    required this.subject,
    this.memberId,
    required this.lastMessageAt,
    this.memberName = '',
    this.refType,
    this.refId,
    this.refLabel,
    this.resolved = false,
    this.lastBody,
    this.lastSenderId,
    this.isUnread = false,
    this.isGroup = false,
    this.lastHidden = false,
  });

  factory MessageThread.fromJson(Map<String, dynamic> j) => MessageThread(
    id: j['id'] as String,
    messId: j['mess_id'] as String,
    memberId: j['member_id'] as String?,
    subject: j['subject'] as String,
    memberName: j['member_name'] as String? ?? '',
    refType: j['ref_type'] as String?,
    refId: j['ref_id'] as String?,
    refLabel: j['ref_label'] as String?,
    resolved: j['status'] == 'resolved',
    lastBody: j['last_body'] as String?,
    lastSenderId: j['last_sender_id'] as String?,
    isUnread: j['is_unread'] as bool? ?? false,
    isGroup: j['kind'] == 'group',
    lastHidden: j['last_hidden'] as bool? ?? false,
    lastMessageAt: DateTime.parse(j['last_message_at'] as String),
  );

  final String id;
  final String messId;

  /// The member side (`mess_members.id`); null for the mess group.
  final String? memberId;
  final String memberName;
  final String subject;
  final String? refType;
  final String? refId;
  final String? refLabel;
  final bool resolved;
  final String? lastBody;
  final String? lastSenderId;
  final bool isUnread;

  /// The mess's one group conversation (supabase 0023).
  final bool isGroup;

  /// The last message was removed (shown as a placeholder).
  final bool lastHidden;
  final DateTime lastMessageAt;
}

/// One message. [pending] / [failed] mark my optimistic, unsent ones.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.body,
    required this.createdAt,
    this.senderId,
    this.pending = false,
    this.failed = false,
    this.hidden = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    threadId: j['thread_id'] as String,
    senderId: j['sender_id'] as String?,
    body: j['body'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    hidden: j['hidden_at'] != null,
  );

  final String id;
  final String threadId;

  /// Auth user id; null once the sender deleted their account.
  final String? senderId;
  final String body;
  final DateTime createdAt;
  final bool pending;
  final bool failed;

  /// Removed from the group; [body] is empty.
  final bool hidden;
}

const messageSubjectMax = 80;
const messageBodyMax = 1000;
