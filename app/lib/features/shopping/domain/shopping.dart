import '../../../core/dates.dart';

/// One line of a bazar list (supabase 0040 `shopping_items`).
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    this.qty,
    this.unit,
    this.bought = false,
    this.price,
    this.extra = false,
    this.sort = 0,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'] as String,
    listId: json['list_id'] as String,
    name: json['name'] as String,
    qty: double.tryParse('${json['qty']}'),
    unit: json['unit'] as String?,
    bought: json['bought'] == true,
    price: double.tryParse('${json['price']}'),
    extra: json['extra'] == true,
    sort: (json['sort'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String listId;
  final String name;
  final double? qty;
  final String? unit;
  final bool bought;
  final double? price;

  /// Added by the shopper on the spot, not planned.
  final bool extra;
  final int sort;

  ShoppingItem copyWith({
    String? name,
    double? qty,
    String? unit,
    bool? bought,
    Object? price = _keep,
  }) => ShoppingItem(
    id: id,
    listId: listId,
    name: name ?? this.name,
    qty: qty ?? this.qty,
    unit: unit ?? this.unit,
    bought: bought ?? this.bought,
    price: identical(price, _keep) ? this.price : (price as num?)?.toDouble(),
    extra: extra,
    sort: sort,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'list_id': listId,
    'name': name,
    'qty': qty,
    'unit': unit,
    'bought': bought,
    'price': price,
    'extra': extra,
    'sort': sort,
  };

  static const _keep = Object();
}

/// A bazar list: planned before the trip, ticked and priced while shopping,
/// then sent in as a bazar. `open` → `submitted` (waiting for a manager) →
/// `done`; a rejected one goes back to `open`.
class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.messId,
    required this.createdBy,
    required this.date,
    required this.status,
    this.assigneeId,
    this.title,
    this.note,
    this.rejectReason,
    this.items = const [],
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
    id: json['id'] as String,
    messId: json['mess_id'] as String,
    createdBy: json['created_by'] as String,
    assigneeId: json['assignee_id'] as String?,
    date: DateTime.parse(json['date'] as String),
    title: json['title'] as String?,
    note: json['note'] as String?,
    status: json['status'] as String,
    rejectReason: json['reject_reason'] as String?,
    items: [
      for (final i in (json['shopping_items'] as List? ?? const []))
        ShoppingItem.fromJson(i as Map<String, dynamic>),
    ]..sort((a, b) => a.sort.compareTo(b.sort)),
  );

  final String id;
  final String messId;
  final String createdBy;
  final String? assigneeId;
  final DateTime date;
  final String? title;
  final String? note;
  final String status;
  final String? rejectReason;
  final List<ShoppingItem> items;

  bool get isOpen => status == 'open';

  /// The member who goes shopping.
  String get shopperId => assigneeId ?? createdBy;

  int get boughtCount => items.where((i) => i.bought).length;

  /// What the ticked, priced items add up to.
  double get total =>
      items.where((i) => i.bought).fold(0, (sum, i) => sum + (i.price ?? 0));

  ShoppingList copyWith({List<ShoppingItem>? items, String? status}) =>
      ShoppingList(
        id: id,
        messId: messId,
        createdBy: createdBy,
        assigneeId: assigneeId,
        date: date,
        title: title,
        note: note,
        status: status ?? this.status,
        rejectReason: rejectReason,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'mess_id': messId,
    'created_by': createdBy,
    'assignee_id': assigneeId,
    'date': isoDate(date),
    'title': title,
    'note': note,
    'status': status,
    'reject_reason': rejectReason,
    'shopping_items': [for (final i in items) i.toJson()],
  };
}
