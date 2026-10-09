import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dates.dart';
import '../../../core/db/db.dart';
import '../../../core/db/sync.dart';
import '../../../core/errors.dart';
import '../../../core/ids.dart';
import '../../month/domain/month.dart';
import '../domain/money.dart';

const moneyPageSize = 50;

/// Bazars are offline-first (Drift + sync queue, keyed on the client UUID);
/// expenses, deposits and months stay online-only.
class MoneyRepository {
  MoneyRepository(this._client, this._db, this._sync);

  final SupabaseClient _client;
  final AppDb _db;
  final SyncService _sync;

  /// Pulls a page when online, then answers from Drift (unsent bazars too).
  // ponytail: offsets count local rows, so a page boundary may shift by the
  // number of unsent bazars; fine below hundreds of bazars a month.
  Future<List<Bazar>> bazars(String messId, MonthPeriod p, {int from = 0}) =>
      guard(() async {
        try {
          final rows = await guard(
            () => _client
                .from('bazars')
                .select('*, bazar_items(*)')
                .eq('mess_id', messId)
                .isFilter('deleted_at', null)
                .gte('date', isoDate(p.start))
                .lt('date', isoDate(p.end))
                .order('date', ascending: false)
                .order('created_at', ascending: false)
                .order('sort', ascending: true, referencedTable: 'bazar_items')
                .range(from, from + moneyPageSize - 1)
                .retry(enabled: false),
          );
          await _mergeBazars(messId, p, rows, replace: from == 0);
        } on AppFailure catch (e) {
          if (e.kind != FailureKind.network) rethrow;
        }
        final local =
            await (_inPeriod(messId, p)
                  ..orderBy([
                    (b) => OrderingTerm.desc(b.date),
                    (b) => OrderingTerm.desc(b.createdAt),
                  ])
                  ..limit(moneyPageSize, offset: from))
                .get();
        final items =
            await (_db.select(_db.bazarItems)
                  ..where((i) => i.bazarId.isIn(local.map((b) => b.id)))
                  ..orderBy([(i) => OrderingTerm.asc(i.sort)]))
                .get();
        return [
          for (final b in local)
            Bazar(
              id: b.id,
              messId: b.messId,
              date: DateTime.parse(b.date),
              amount: b.amount,
              buyerMemberId: b.buyerMemberId,
              paidByMemberId: b.paidByMemberId,
              note: b.note,
              source: b.source,
              receiptPath: b.receiptPath,
              items: [
                for (final i in items)
                  if (i.bazarId == b.id)
                    BazarItem(
                      id: i.id,
                      name: i.name,
                      price: i.price,
                      qty: i.qty,
                      unit: i.unit,
                    ),
              ],
            ),
        ];
      });

  /// Every item name on this mess's bazars kept on the device (frequency
  /// source for the item picker).
  Future<List<String>> itemNames(String messId) async {
    final q = _db.select(_db.bazarItems).join([
      innerJoin(_db.bazars, _db.bazars.id.equalsExp(_db.bazarItems.bazarId)),
    ])..where(_db.bazars.messId.equals(messId));
    return [for (final r in await q.get()) r.readTable(_db.bazarItems).name];
  }

  SimpleSelectStatement<$BazarsTable, LocalBazar> _inPeriod(
    String messId,
    MonthPeriod p,
  ) => _db.select(_db.bazars)
    ..where(
      (b) =>
          b.messId.equals(messId) &
          b.date.isBiggerOrEqualValue(isoDate(p.start)) &
          b.date.isSmallerThanValue(isoDate(p.end)),
    );

  /// Server rows replace local ones, except bazars with a queued write: those
  /// keep the local copy unless the server's is newer (last write wins).
  /// [replace]: first page, so synced bazars missing from it are dropped.
  Future<void> _mergeBazars(
    String messId,
    MonthPeriod p,
    List<Map<String, dynamic>> rows, {
    required bool replace,
  }) => _db.transaction(() async {
    final ops = await _db.opsFor('bazars');
    final local = {for (final b in await _inPeriod(messId, p).get()) b.id: b};
    if (replace) {
      for (final id in local.keys) {
        if (!ops.containsKey(id)) await _deleteLocal(id);
      }
    }
    for (final r in rows) {
      final b = Bazar.fromJson(r);
      final theirs = DateTime.parse(r['updated_at'] as String);
      final op = ops[b.id];
      if (op != null) {
        final mine = local[b.id]?.updatedAt;
        if (op.status == opSyncing || (mine != null && !theirs.isAfter(mine))) {
          continue;
        }
        await _db.deleteOp(op.id);
      }
      await _writeLocal(
        b,
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: theirs,
      );
    }
  });

  Future<void> _writeLocal(
    Bazar b, {
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    await _db
        .into(_db.bazars)
        .insert(
          BazarsCompanion.insert(
            id: b.id,
            messId: b.messId,
            date: isoDate(b.date),
            amount: b.amount,
            buyerMemberId: Value(b.buyerMemberId),
            paidByMemberId: Value(b.paidByMemberId),
            note: Value(b.note),
            source: b.source,
            receiptPath: Value(b.receiptPath),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          // An edit keeps the bazar's place in the list.
          onConflict: DoUpdate.withExcluded(
            (old, excluded) => BazarsCompanion.custom(
              date: excluded.date,
              amount: excluded.amount,
              buyerMemberId: excluded.buyerMemberId,
              paidByMemberId: excluded.paidByMemberId,
              note: excluded.note,
              source: excluded.source,
              receiptPath: excluded.receiptPath,
              updatedAt: excluded.updatedAt,
            ),
          ),
        );
    await (_db.delete(
      _db.bazarItems,
    )..where((i) => i.bazarId.equals(b.id))).go();
    await _db.batch(
      (batch) => batch.insertAll(_db.bazarItems, [
        for (final (n, i) in b.items.indexed)
          BazarItemsCompanion.insert(
            id: i.id,
            bazarId: b.id,
            name: i.name,
            price: i.price,
            qty: Value(i.qty),
            unit: Value(i.unit),
            sort: n,
          ),
      ]),
    );
  }

  Future<void> _deleteLocal(String id) async {
    await (_db.delete(_db.bazarItems)..where((i) => i.bazarId.equals(id))).go();
    await (_db.delete(_db.bazars)..where((b) => b.id.equals(id))).go();
  }

  Future<List<Expense>> expenses(
    String messId,
    MonthPeriod p, {
    int from = 0,
  }) => guard(() async {
    final rows = await _desc(
      'expenses',
      messId,
      p,
      from,
      select: '*, expense_shares(member_id, weight)',
    );
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
    int from, {
    String select = '*',
  }) => _client
      .from(table)
      .select(select)
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
        .order('sort_order', ascending: true);
    return rows.map(ExpenseCategory.fromJson).toList();
  });

  /// Saves locally and queues the upsert (client id → idempotent; item lines
  /// are replaced). Waits for one sync attempt; offline it returns at once.
  Future<void> saveBazar(Bazar b) => guard(() async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _writeLocal(b, createdAt: now, updatedAt: now);
      await _db.enqueue('bazars', b.id, uuidV4(), {
        ...b.toJson(),
        'bazar_items': b.itemsJson(),
      });
    });
    await _sync.drain();
  });

  /// Upserts the expense, then replaces its shares (empty = equal split).
  // ponytail: two calls, not one transaction; a failed second call leaves the
  // old shares and shows the error, and saving again repairs it (idempotent).
  Future<void> saveExpense(Expense e) => guard(() async {
    requireRows(await _client.from('expenses').upsert(e.toJson()).select('id'));
    await _client.rpc(
      'set_expense_shares',
      params: {'p_expense': e.id, 'p_shares': e.sharesJson()},
    );
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

  /// Online only. A bazar whose sync failed (e.g. month closed) is dropped
  /// locally; the next pull restores any copy the server already has.
  Future<void> deleteBazar(String id) => guard(() async {
    final op = (await _db.opsFor('bazars'))[id];
    if (op?.status != opFailed) await _softDelete('bazars', id);
    await _db.transaction(() async {
      if (op != null) await _db.deleteOp(op.id);
      await _deleteLocal(id);
    });
  });
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
