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
  final verb = switch (e.action) {
    'insert' => l.auditAdded,
    'delete' => l.auditDeleted,
    _ when softDeleted => l.auditDeleted,
    _ => l.auditChanged,
  };
  final (thing, detail) = switch (e.entity) {
    'bazars' => (l.auditBazar, money()),
    'expenses' => (l.auditExpense, money()),
    'deposits' => (l.auditDepositOf(name(row['member_id'])), money()),
    'meal_entries' => (
      l.auditMealOf(name(row['member_id'])),
      date(row['date']),
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
