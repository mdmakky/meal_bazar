/// A meal-off lead to save: `(minutes: null)` = the previous-day cutoff rule.
typedef MealOffLead = ({int? minutes});

class Mess {
  const Mess({
    required this.id,
    required this.name,
    required this.monthStartDay,
    required this.currency,
    required this.mealOffCutoff,
    this.mealOffLeadMinutes,
    this.address,
    this.createdBy,
    this.fixedRate = false,
    this.fixedMealRate,
    this.dueReminderEvery,
    this.dueReminderMin = 0,
  });

  factory Mess.fromJson(Map<String, dynamic> json) => Mess(
    id: json['id'] as String,
    name: json['name'] as String,
    monthStartDay: (json['month_start_day'] as num).toInt(),
    currency: json['currency'] as String? ?? '৳',
    mealOffCutoff: json['meal_off_cutoff'] as String? ?? '22:00:00',
    mealOffLeadMinutes: (json['meal_off_lead_minutes'] as num?)?.toInt(),
    address: json['address'] as String?,
    createdBy: json['created_by'] as String?,
    fixedRate: json['meal_rate_mode'] == 'fixed',
    fixedMealRate: (json['fixed_meal_rate'] as num?)?.toDouble(),
    dueReminderEvery: (json['due_reminder_every'] as num?)?.toInt(),
    dueReminderMin: double.tryParse('${json['due_reminder_min']}') ?? 0,
  );

  final String id;
  final String name;

  /// 1–28.
  final int monthStartDay;
  final String currency;

  /// Postgres `time`, e.g. '22:00:00'.
  final String mealOffCutoff;

  /// How long before a meal's serve time a member may still switch it off
  /// (0–2880). Null: the previous day at [mealOffCutoff] (PRODUCT_RULES §1).
  final int? mealOffLeadMinutes;
  final String? address;
  final String? createdBy;

  /// `meal_rate_mode = 'fixed'`: members pay [fixedMealRate] per meal
  /// instead of the calculated rate (PRODUCT_RULES §3).
  final bool fixedRate;
  final double? fixedMealRate;

  /// Automatic due reminders every N days (1–30); null = off (supabase 0030).
  final int? dueReminderEvery;

  /// Only dues above this are reminded.
  final double dueReminderMin;
}

/// One of the manager's due-reminder texts; `{name}`, `{amount}` and
/// `{mess}` are filled in by the server.
typedef DueReminderText = ({String id, String body});
