class Mess {
  const Mess({
    required this.id,
    required this.name,
    required this.monthStartDay,
    required this.currency,
    required this.mealOffCutoff,
    this.address,
    this.createdBy,
  });

  factory Mess.fromJson(Map<String, dynamic> json) => Mess(
    id: json['id'] as String,
    name: json['name'] as String,
    monthStartDay: (json['month_start_day'] as num).toInt(),
    currency: json['currency'] as String? ?? '৳',
    mealOffCutoff: json['meal_off_cutoff'] as String? ?? '22:00:00',
    address: json['address'] as String?,
    createdBy: json['created_by'] as String?,
  );

  final String id;
  final String name;

  /// 1–28.
  final int monthStartDay;
  final String currency;

  /// Postgres `time`, e.g. '22:00:00'.
  final String mealOffCutoff;
  final String? address;
  final String? createdBy;
}
