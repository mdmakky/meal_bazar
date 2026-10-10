/// What an invite code is for, from the `invite_preview` RPC (supabase 0034).
class InvitePreview {
  const InvitePreview({
    required this.valid,
    this.reason,
    this.messName,
    this.inviterName,
    this.inviteeName,
    this.autoApprove = false,
  });

  factory InvitePreview.fromJson(Map<String, dynamic> json) => InvitePreview(
    valid: json['valid'] == true,
    reason: json['reason'] as String?,
    messName: json['mess_name'] as String?,
    inviterName: json['inviter_name'] as String?,
    inviteeName: json['invitee_name'] as String?,
    autoApprove: json['auto_approve'] == true,
  );

  final bool valid;

  /// 'revoked' | 'used' | 'expired' | 'unknown' when not [valid].
  final String? reason;
  final String? messName;
  final String? inviterName;
  final String? inviteeName;

  /// A link invite: joining makes you an active member at once.
  final bool autoApprove;
}
