import '../../../core/dates.dart';

/// One `bazar_duties` row: who does the bazar on [date].
class BazarDuty {
  const BazarDuty({
    required this.id,
    required this.messId,
    required this.date,
    required this.memberId,
    this.note,
    this.done = false,
  });

  factory BazarDuty.fromJson(Map<String, dynamic> json) => BazarDuty(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    date: DateTime.parse(json['date'] as String),
    memberId: json['member_id'] as String,
    note: json['note'] as String?,
    done: json['done'] as bool? ?? false,
  );

  final String id;
  final String messId;
  final DateTime date;
  final String memberId;
  final String? note;
  final bool done;

  BazarDuty copyWith({
    DateTime? date,
    String? memberId,
    String? note,
    bool? done,
  }) => BazarDuty(
    id: id,
    messId: messId,
    date: date ?? this.date,
    memberId: memberId ?? this.memberId,
    note: note ?? this.note,
    done: done ?? this.done,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'date': isoDate(date),
    'member_id': memberId,
    'note': note,
    'done': done,
  };
}

/// What the "পালা বানান" sheet asks for: members in order, from [from],
/// one duty every [every] days, across [days] days.
class DutyRotation {
  const DutyRotation({
    required this.memberIds,
    required this.from,
    required this.days,
    this.every = 1,
  });

  final List<String> memberIds;
  final DateTime from;
  final int days;
  final int every;

  /// Params for the `generate_duty_rotation` RPC.
  Map<String, dynamic> params(String messId) => {
    'p_mess': messId,
    'p_from': isoDate(from),
    'p_days': days,
    'p_member_ids': memberIds,
    'p_every': every,
  };
}
