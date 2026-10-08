import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dates.dart';
import '../../../core/errors.dart';
import '../../month/domain/month.dart';
import '../domain/money.dart';

const moneyPageSize = 50;

class MoneyRepository {
  MoneyRepository(this._client);

  final SupabaseClient _client;

  Future<List<Bazar>> bazars(String messId, MonthPeriod p, {int from = 0}) =>
      guard(() async {
        final rows = await _client
            .from('bazars')
            .select('*, bazar_items(*)')
            .eq('mess_id', messId)
            .isFilter('deleted_at', null)
            .gte('date', isoDate(p.start))
            .lt('date', isoDate(p.end))
            .order('date', ascending: false)
            .order('created_at', ascending: false)
            .order('sort', referencedTable: 'bazar_items')
            .range(from, from + moneyPageSize - 1);
        return rows.map(Bazar.fromJson).toList();
      });

  Future<List<Expense>> expenses(
    String messId,
    MonthPeriod p, {
    int from = 0,
  }) => guard(() async {
    final rows = await _desc('expenses', messId, p, from);
    return rows.map(Expense.fromJson).toList();
  });

  Future<List<Deposit>> deposits(
    String messId,
    MonthPeriod p, {
    int from = 0,
  }) => guard(() async {
    final rows = await _desc('deposits', messId, p, from);
    return rows.map(Deposit.fromJson).toList();
  });

  Future<List<Map<String, dynamic>>> _desc(
    String table,
    String messId,
    MonthPeriod p,
    int from,
  ) => _client
      .from(table)
      .select()
      .eq('mess_id', messId)
      .isFilter('deleted_at', null)
      .gte('date', isoDate(p.start))
      .lt('date', isoDate(p.end))
      .order('date', ascending: false)
      .order('created_at', ascending: false)
      .range(from, from + moneyPageSize - 1);

  Future<List<ExpenseCategory>> categories(String messId) => guard(() async {
    final rows = await _client
        .from('expense_categories')
        .select()
        .eq('mess_id', messId)
        .eq('archived', false)
        .order('sort_order');
    return rows.map(ExpenseCategory.fromJson).toList();
  });

  /// Create or update (client id → idempotent), then replace its item lines.
  Future<void> saveBazar(Bazar b) => guard(() async {
    requireRows(await _client.from('bazars').upsert(b.toJson()).select('id'));
    await _client.from('bazar_items').delete().eq('bazar_id', b.id);
    if (b.items.isNotEmpty) {
      await _client.from('bazar_items').insert(b.itemsJson());
    }
  });

  Future<void> saveExpense(Expense e) => guard(() async {
    requireRows(await _client.from('expenses').upsert(e.toJson()).select('id'));
  });

  Future<void> saveDeposit(Deposit d) => guard(() async {
    requireRows(await _client.from('deposits').upsert(d.toJson()).select('id'));
  });

  /// A member's own deposit; the server stores it as `pending` for the caller's
  /// member row (`record_my_deposit`). Idempotent on [Deposit.id].
  Future<void> recordMyDeposit(Deposit d) => guard(
    () => _client.rpc(
      'record_my_deposit',
      params: {
        'p_mess': d.messId,
        'p_id': d.id,
        'p_date': isoDate(d.date),
        'p_amount': d.amount,
        'p_method': d.method.name,
        'p_trx_id': d.trxId,
        'p_note': d.note,
        'p_screenshot_path': d.screenshotPath,
      },
    ),
  );

  /// Manager: pending → verified ([approve]) or rejected.
  Future<void> verifyDeposit(String id, {required bool approve}) => guard(
    () => _client.rpc(
      'verify_deposit',
      params: {'p_id': id, 'p_approve': approve},
    ),
  );

  Future<void> deleteBazar(String id) => _softDelete('bazars', id);
  Future<void> deleteExpense(String id) => _softDelete('expenses', id);
  Future<void> deleteDeposit(String id) => _softDelete('deposits', id);

  Future<void> _softDelete(String table, String id) => guard(() async {
    requireRows(
      await _client
          .from(table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id)
          .select('id'),
    );
  });

  /// Months that were ever closed, newest first.
  Future<List<MessMonth>> months(String messId) => guard(() async {
    final rows = await _client
        .from('months')
        .select()
        .eq('mess_id', messId)
        .order('start_date', ascending: false);
    return rows.map(MessMonth.fromJson).toList();
  });

  /// Closes the billing period containing [day]. Returns the month id.
  Future<String> closeMonth(String messId, DateTime day) => guard(() async {
    final id = await _client.rpc(
      'close_month',
      params: {'p_mess': messId, 'p_date': isoDate(day)},
    );
    return id as String;
  });

  Future<void> reopenMonth(String monthId, String reason) => guard(
    () => _client.rpc(
      'reopen_month',
      params: {'p_month': monthId, 'p_reason': reason.trim()},
    ),
  );
}
