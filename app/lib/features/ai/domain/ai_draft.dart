// Gateway drafts (ai-gateway/lib/schemas.ts). Drafts only: nothing here is
// saved until the user confirms through the normal repositories.

/// The gateway answered `{unavailable: true, reason}`: AI is off, over quota,
/// or every provider failed. The app carries on without AI.
class AiUnavailable implements Exception {
  const AiUnavailable(this.reason);

  /// `disabled`, `quota` or `providers`.
  final String reason;

  @override
  String toString() => 'AiUnavailable($reason)';
}

double _d(Object? v) => (v as num).toDouble();

class MealDraftEntry {
  const MealDraftEntry({
    required this.memberId,
    required this.mealTypeId,
    required this.count,
    required this.guestCount,
    required this.isOff,
  });

  factory MealDraftEntry.fromJson(Map<String, dynamic> j) => MealDraftEntry(
    memberId: j['member_id'] as String,
    mealTypeId: j['meal_type_id'] as String,
    count: _d(j['count']),
    guestCount: (j['guest_count'] as num).toInt(),
    isOff: j['is_off'] as bool,
  );

  final String memberId;
  final String mealTypeId;
  final double count;
  final int guestCount;
  final bool isOff;
}

class MealDraft {
  const MealDraft({
    required this.entries,
    required this.unmatched,
    required this.confidence,
  });

  factory MealDraft.fromJson(Map<String, dynamic> j) => MealDraft(
    entries: [
      for (final e in j['entries'] as List)
        MealDraftEntry.fromJson(e as Map<String, dynamic>),
    ],
    unmatched: [for (final u in j['unmatched'] as List) '$u'],
    confidence: _d(j['confidence']),
  );

  final List<MealDraftEntry> entries;
  final List<String> unmatched;
  final double confidence;
}

class BazarDraftItem {
  const BazarDraftItem({
    required this.name,
    required this.price,
    this.qty,
    this.unit,
  });

  factory BazarDraftItem.fromJson(Map<String, dynamic> j) => BazarDraftItem(
    name: j['name'] as String,
    qty: j['qty'] == null ? null : _d(j['qty']),
    unit: j['unit'] as String?,
    price: _d(j['price']),
  );

  final String name;
  final double? qty;
  final String? unit;

  /// Line total.
  final double price;
}

class BazarDraft {
  const BazarDraft({
    required this.items,
    required this.total,
    required this.totalMatchesItems,
    this.notes = '',
  });

  factory BazarDraft.fromJson(Map<String, dynamic> j) => BazarDraft(
    items: [
      for (final i in j['items'] as List)
        BazarDraftItem.fromJson(i as Map<String, dynamic>),
    ],
    total: j['total'] == null ? null : _d(j['total']),
    totalMatchesItems: j['total_matches_items'] as bool,
    notes: (j['notes'] as String?) ?? '',
  );

  final List<BazarDraftItem> items;

  /// The receipt's printed total; null when unreadable. After review this is
  /// the total the user chose.
  final double? total;
  final bool totalMatchesItems;
  final String notes;
}
