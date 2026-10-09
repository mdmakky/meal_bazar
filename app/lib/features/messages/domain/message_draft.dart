/// What a new message starts from: the entry a "report a problem" is about.
class MessageDraft {
  const MessageDraft({this.refType, this.refId, this.refLabel});

  /// `deposit`, `bazar`, `expense`, `meal` or `other`.
  final String? refType;
  final String? refId;
  final String? refLabel;
}
