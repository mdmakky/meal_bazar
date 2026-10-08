// Money rows (0003_money.sql) and month rows (0004_months.sql).
// The app never computes balances; amounts here are only entered and shown.

import '../../../core/dates.dart';
import '../../month/domain/month.dart';

/// Matches SQL enum `split_method`.
enum SplitMethod { meal, equal }

/// Matches SQL enum `pay_method`.
enum PayMethod {
  cash,
  bkash,
  nagad,
  bank,
  other;

  bool get hasTrxId => this == bkash || this == nagad || this == bank;
}

/// Matches SQL enum `deposit_status`.
enum DepositStatus { verified, pending, rejected }

class BazarItem {
  const BazarItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty,
    this.unit,
  });

  factory BazarItem.fromJson(Map<String, dynamic> j) => BazarItem(
    id: j['id'] as String,
    name: j['name'] as String,
    price: _d(j['price']),
    qty: j['qty'] == null ? null : _d(j['qty']),
    unit: j['unit'] as String?,
  );

  final String id;
  final String name;

  /// Line total, not unit price.
  final double price;
  final double? qty;
  final String? unit;
}

class Bazar {
  const Bazar({
    required this.id,
    required this.messId,
    required this.date,
    required this.amount,
    this.buyerMemberId,
    this.paidByMemberId,
    this.note,
    this.items = const [],
    this.source = 'app',
  });

  factory Bazar.fromJson(Map<String, dynamic> j) => Bazar(
    id: j['id'] as String,
    messId: j['mess_id'] as String,
    date: DateTime.parse(j['date'] as String),
    amount: _d(j['amount']),
    buyerMemberId: j['buyer_member_id'] as String?,
    paidByMemberId: j['paid_by_member_id'] as String?,
    note: j['note'] as String?,
    source: j['source'] as String? ?? 'app',
    items: [
      for (final i in (j['bazar_items'] as List? ?? const []))
        BazarItem.fromJson(i as Map<String, dynamic>),
    ],
  );

  final String id;
  final String messId;
  final DateTime date;
  final double amount;
  final String? buyerMemberId;

  /// Null = paid from the mess fund; set = that member's own pocket (credit).
  final String? paidByMemberId;
  final String? note;
  final List<BazarItem> items;

  /// 'ai' when prefilled from a confirmed AI draft.
  final String source;

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'date': isoDate(date),
    'amount': amount,
    'buyer_member_id': buyerMemberId,
    'paid_by_member_id': paidByMemberId,
    'note': note,
    'source': source,
  };

  List<Map<String, dynamic>> itemsJson() => [
    for (final (n, i) in items.indexed)
      {
        'id': i.id,
        'bazar_id': id,
        'mess_id': messId,
        'name': i.name,
        'qty': i.qty,
        'unit': i.unit,
        'price': i.price,
        'sort': n,
      },
  ];
}

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.defaultSplit,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> j) => ExpenseCategory(
    id: j['id'] as String,
    name: j['name'] as String,
    defaultSplit: SplitMethod.values.byName(j['default_split'] as String),
  );

  final String id;
  final String name;
  final SplitMethod defaultSplit;
}

class Expense {
  const Expense({
    required this.id,
    required this.messId,
    required this.date,
    required this.categoryId,
    required this.amount,
    required this.split,
    this.paidByMemberId,
    this.note,
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    messId: j['mess_id'] as String,
    date: DateTime.parse(j['date'] as String),
    categoryId: j['category_id'] as String,
    amount: _d(j['amount']),
    split: SplitMethod.values.byName(j['split'] as String),
    paidByMemberId: j['paid_by_member_id'] as String?,
    note: j['note'] as String?,
  );

  final String id;
  final String messId;
  final DateTime date;
  final String categoryId;
  final double amount;
  final SplitMethod split;
  final String? paidByMemberId;
  final String? note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'date': isoDate(date),
    'category_id': categoryId,
    'amount': amount,
    'split': split.name,
    'paid_by_member_id': paidByMemberId,
    'note': note,
  };
}

class Deposit {
  const Deposit({
    required this.id,
    required this.messId,
    required this.memberId,
    required this.date,
    required this.amount,
    this.method = PayMethod.cash,
    this.trxId,
    this.status = DepositStatus.verified,
    this.note,
  });

  factory Deposit.fromJson(Map<String, dynamic> j) => Deposit(
    id: j['id'] as String,
    messId: j['mess_id'] as String,
    memberId: j['member_id'] as String,
    date: DateTime.parse(j['date'] as String),
    amount: _d(j['amount']),
    method: PayMethod.values.byName(j['method'] as String),
    trxId: j['trx_id'] as String?,
    status: DepositStatus.values.byName(j['status'] as String),
    note: j['note'] as String?,
  );

  final String id;
  final String messId;
  final String memberId;
  final DateTime date;
  final double amount;
  final PayMethod method;
  final String? trxId;
  final DepositStatus status;
  final String? note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'member_id': memberId,
    'date': isoDate(date),
    'amount': amount,
    'method': method.name,
    'trx_id': trxId,
    'status': status.name,
    'note': note,
  };
}

/// A `months` row. Only months that were closed at least once have a row.
class MessMonth {
  const MessMonth({
    required this.id,
    required this.start,
    required this.end,
    required this.closed,
  });

  factory MessMonth.fromJson(Map<String, dynamic> j) => MessMonth(
    id: j['id'] as String,
    start: DateTime.parse(j['start_date'] as String),
    end: DateTime.parse(j['end_date'] as String),
    closed: j['status'] == 'closed',
  );

  final String id;
  final DateTime start;

  /// Exclusive.
  final DateTime end;
  final bool closed;
}

final _amount = RegExp(r'^\d+(\.\d{1,2})?$');

/// A typed amount: Bangla or Latin digits, ≥ 0, at most 2 decimals, below
/// the `numeric(12,2)` limit. Null when invalid or empty.
double? parseAmount(String raw) {
  final s = raw
      .trim()
      .replaceAll(',', '')
      .replaceAllMapped(
        RegExp('[০-৯]'),
        (m) => '${m[0]!.codeUnitAt(0) - 0x09E6}',
      );
  if (!_amount.hasMatch(s)) return null;
  final v = double.parse(s);
  return v < 1e10 ? v : null;
}

/// Sum of item line prices, in paisa to stay exact. Only used to suggest a
/// bazar total; the stored amount is whatever the user confirms.
double itemsTotal(Iterable<double> prices) =>
    prices.fold<int>(0, (s, p) => s + (p * 100).round()) / 100;

/// The parts of a member's bill, as the SQL reported them.
enum BillPart { opening, credit, food, extra }

typedef BillLine = ({BillPart part, double amount});

/// "Explain my bill": opening + credit − food − extra = closing.
/// Only attaches signs to SQL figures; the lines sum to [MemberBalance.closingBalance].
List<BillLine> billLines(MemberBalance b) => [
  (part: BillPart.opening, amount: b.openingBalance),
  (part: BillPart.credit, amount: b.credit),
  (part: BillPart.food, amount: -b.foodCost),
  (part: BillPart.extra, amount: -b.extraCost),
];

double _d(Object? v) => v is num ? v.toDouble() : double.parse(v as String);
