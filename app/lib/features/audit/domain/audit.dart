import '../../../core/format.dart';
import '../../../core/l10n/gen/app_localizations.dart';

/// One `audit_log` row.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.entity,
    required this.at,
    this.actorId,
    this.entityId,
    this.oldRow,
    this.newRow,
    this.source = 'app',
    this.reason,
    this.refType,
    this.refId,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
    id: json['id'] as int,
    action: json['action'] as String,
    entity: json['entity'] as String,
    at: DateTime.parse(json['at'] as String),
    actorId: json['actor_id'] as String?,
    entityId: json['entity_id'] as String?,
    oldRow: json['old'] as Map<String, dynamic>?,
    newRow: json['new'] as Map<String, dynamic>?,
    source: json['source'] as String? ?? 'app',
    reason: json['reason'] as String?,
    refType: json['ref_type'] as String?,
    refId: json['ref_id'] as String?,
  );

  final int id;

  /// insert | update | delete | an RPC name (close_month, delete_account…).
  final String action;
  final String entity;
  final DateTime at;
  final String? actorId;
  final String? entityId;
  final Map<String, dynamic>? oldRow;
  final Map<String, dynamic>? newRow;

  /// app | ai | system.
  final String source;
  final String? reason;

  /// `my_activity` only: 'meal' | 'deposit' | 'bazar' | 'expense', and the
  /// row it is about (for "report a problem").
  final String? refType;
  final String? refId;
}

/// Which entities each filter chip shows; null = all.
enum AuditFilter {
  all(null),
  meals(['meal_entries', 'meal_types']),
  money(['bazars', 'expenses', 'deposits', 'months']),
  members(['mess_members']);

  const AuditFilter(this.entities);
  final List<String>? entities;
}

/// A plain-language sentence, e.g. "রহিম বাজার যোগ করেছেন ৳১,০০০".
///
/// [names] maps both user ids (for actors) and member ids (for rows that
/// reference a member) to display names.
String describeAudit(
  AppLocalizations l,
  AuditEntry e,
  Map<String, String> names,
) {
  final bn = l.localeName == 'bn';
  final row = e.newRow ?? e.oldRow ?? const <String, dynamic>{};
  String name(Object? id) => names[id] ?? l.auditSomeone;
  final actor = e.actorId == null ? l.auditSystem : name(e.actorId);

  String date(Object? iso) {
    final d = DateTime.tryParse('$iso');
    return d == null
        ? ''
        : Fmt.dateLong(d, locale: l.localeName, banglaDigits: bn);
  }

  String money() {
    final a = num.tryParse('${row['amount']}');
    return a == null ? '' : Fmt.money(a, banglaDigits: bn);
  }

  switch (e.action) {
    case 'close_month':
      return '${l.auditMonthClosed(actor)} ${date(row['start_date'])}'.trim();
    case 'reopen_month':
      return '${l.auditMonthReopened(actor)} ${date(row['start_date'])}'.trim();
    case 'delete_account':
      return l.auditAccountDeleted(name(e.entityId));
  }

  final softDeleted =
      e.oldRow?['deleted_at'] == null && e.newRow?['deleted_at'] != null;
  final status = e.entity == 'deposits' && e.action == 'update'
      ? (e.oldRow?['status'], e.newRow?['status'])
      : null;
  final verb = switch (e.action) {
    'insert' => l.auditAdded,
    'delete' => l.auditDeleted,
    _ when softDeleted => l.auditDeleted,
    _ when status == ('pending', 'verified') => l.auditVerified,
    _ when status == ('pending', 'rejected') => l.auditRejected,
    _ => l.auditChanged,
  };

  // A meal's value: own count (or off), plus guests.
  String meal(Map<String, dynamic>? r) {
    if (r == null || !r.containsKey('count')) return '';
    final guests = num.tryParse('${r['guest_count']}') ?? 0;
    final own = r['is_off'] == true
        ? l.auditOff
        : Fmt.meals(num.tryParse('${r['count']}') ?? 0, banglaDigits: bn);
    return guests > 0 ? '$own +${Fmt.digits('$guests', bangla: bn)}' : own;
  }

  final (from, to) = (meal(e.oldRow), meal(e.newRow));
  final mealChange = switch (e.action) {
    'update' when from.isNotEmpty && to.isNotEmpty && from != to =>
      '$from → $to',
    'insert' => to,
    _ => '',
  };
  final (thing, detail) = switch (e.entity) {
    'bazars' => (l.auditBazar, money()),
    'expenses' => (l.auditExpense, money()),
    'deposits' => (l.auditDepositOf(name(row['member_id'])), money()),
    'meal_entries' => (
      l.auditMealOf(name(row['member_id'])),
      [date(row['date']), mealChange].where((s) => s.isNotEmpty).join(' · '),
    ),
    'meal_types' => (l.auditMealType('${row['name'] ?? ''}'.trim()), ''),
    'mess_members' => (l.auditMember('${row['display_name'] ?? ''}'), ''),
    'messes' => (l.auditMessSettings, ''),
    'bazar_duties' => (
      l.auditDutyOf(name(row['member_id'])),
      date(row['date']),
    ),
    'announcements' => (l.auditNotice('${row['title'] ?? ''}'.trim()), ''),
    'recurring_expenses' => (l.auditRecurring, money()),
    _ => (e.entity, ''),
  };
  return '${l.auditSentence(actor, thing, verb)} $detail'.trim();
}
