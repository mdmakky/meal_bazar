/// What a new message is about; passed as `extra` to `/more/messages/new`.
class MessageDraft {
  const MessageDraft({required this.refType, this.refId, this.refLabel});

  /// 'deposit' | 'bazar' | 'expense' | 'meal' | 'other'.
  final String refType;
  final String? refId;
  final String? refLabel;
}
