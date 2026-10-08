import 'mess.dart';

/// Matches SQL enum `member_role`.
enum MemberRole { manager, member }

/// Matches SQL enum `member_status`.
enum MemberStatus { pending, active, inactive, left }

class Member {
  const Member({
    required this.id,
    required this.messId,
    required this.displayName,
    required this.role,
    required this.status,
    required this.joinedOn,
    this.userId,
    this.leftOn,
    this.room,
    this.notes,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    displayName: json['display_name'] as String,
    role: MemberRole.values.byName(json['role'] as String),
    status: MemberStatus.values.byName(json['status'] as String),
    joinedOn: DateTime.parse(json['joined_on'] as String),
    userId: json['user_id'] as String?,
    leftOn: json['left_on'] == null
        ? null
        : DateTime.parse(json['left_on'] as String),
    room: json['room'] as String?,
    notes: json['notes'] as String?,
  );

  final String id;
  final String messId;
  final String displayName;
  final MemberRole role;
  final MemberStatus status;
  final DateTime joinedOn;

  /// Null for members without an app account (the manager enters for them).
  final String? userId;
  final DateTime? leftOn;
  final String? room;
  final String? notes;

  bool get hasAccount => userId != null;
  bool get isActiveManager =>
      role == MemberRole.manager && status == MemberStatus.active;
}

/// One of my `mess_members` rows with its mess.
class Membership {
  const Membership({required this.member, this.mess});

  /// Parses a `mess_members` row selected with `*, messes(*)`.
  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
    member: Member.fromJson(json),
    mess: json['messes'] == null
        ? null
        : Mess.fromJson(json['messes'] as Map<String, dynamic>),
  );

  final Member member;

  /// Null while pending: RLS hides the mess until the manager approves.
  final Mess? mess;

  String get messId => member.messId;
}
