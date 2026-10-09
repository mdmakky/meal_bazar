// A member's own bazar awaiting the manager (0026 `bazar_requests`). Not a
// bazar: no money math reads it until a manager approves it.

import '../../../core/dates.dart';
import 'money.dart';

/// Matches the SQL check on `bazar_requests.status`.
enum BazarRequestStatus { pending, approved, rejected, cancelled }

class BazarRequest {
  const BazarRequest({
    required this.id,
    required this.messId,
    required this.date,
    required this.amount,
    this.memberId = '',
    this.ownPocket = true,
    this.buyerIds = const [],
    this.items = const [],
    this.note,
    this.receiptPath,
    this.status = BazarRequestStatus.pending,
    this.rejectReason,
  });

  factory BazarRequest.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    return BazarRequest(
      id: id,
      messId: j['mess_id'] as String,
      memberId: j['member_id'] as String,
      date: DateTime.parse(j['date'] as String),
      amount: _d(j['amount']),
      ownPocket: j['own_pocket'] as bool? ?? true,
      buyerIds: [for (final b in j['buyer_ids'] as List? ?? const []) '$b'],
      items: [
        for (final (n, i) in (j['items'] as List? ?? const []).indexed)
          if (i case final Map<String, dynamic> m)
            BazarItem(
              id: '$id-$n',
              name: '${m['name'] ?? ''}',
              price: m['price'] == null ? 0 : _d(m['price']),
              qty: m['qty'] == null ? null : _d(m['qty']),
              unit: m['unit'] as String?,
            ),
      ],
      note: j['note'] as String?,
      receiptPath: j['receipt_path'] as String?,
      status: BazarRequestStatus.values.byName(j['status'] as String),
      rejectReason: j['reject_reason'] as String?,
    );
  }

  /// Client generated: the submit RPC is idempotent on it, and an approved
  /// request's bazar gets the same id.
  final String id;
  final String messId;

  /// The submitter (filled by the server from the caller).
  final String memberId;
  final DateTime date;
  final double amount;

  /// true = the submitter paid (credit on approval); false = the mess fund.
  final bool ownPocket;

  /// Who went: the submitter first, then companions.
  final List<String> buyerIds;
  final List<BazarItem> items;
  final String? note;
  final String? receiptPath;
  final BazarRequestStatus status;
  final String? rejectReason;

  bool get pending => status == BazarRequestStatus.pending;

  /// How it would look as a bazar (for display only).
  Bazar asBazar() => Bazar(
    id: id,
    messId: messId,
    date: date,
    amount: amount,
    buyers: buyerIds,
    paidByMemberId: ownPocket ? memberId : null,
    note: note,
    items: items,
    receiptPath: receiptPath,
  );

  /// `submit_bazar_request` params.
  Map<String, dynamic> params() => {
    'p_mess': messId,
    'p_id': id,
    'p_date': isoDate(date),
    'p_amount': amount,
    'p_own_pocket': ownPocket,
    'p_buyer_ids': buyerIds,
    'p_items': [
      for (final i in items)
        {'name': i.name, 'qty': i.qty, 'unit': i.unit, 'price': i.price},
    ],
    'p_note': note,
    'p_receipt_path': receiptPath,
  };
}

// PostgREST returns numeric as a JSON number, or a string for very long values.
double _d(Object? v) => v is num ? v.toDouble() : double.parse('$v');
