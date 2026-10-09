import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/dates.dart';
import '../../../core/errors.dart';
import '../domain/month.dart';

class MonthRepository {
  MonthRepository(this._client);

  final SupabaseClient _client;

  Future<MonthPeriod> period(String messId, DateTime day) => guard(() async {
    final rows =
        await _client.rpc(
              'month_period',
              params: {'p_mess': messId, 'p_date': isoDate(day)},
            )
            as List;
    final row = rows.single as Map<String, dynamic>;
    return MonthPeriod(
      DateTime.parse(row['start_date'] as String),
      DateTime.parse(row['end_date'] as String),
    );
  });

  Future<MonthTotals> totals(String messId, MonthPeriod p) => guard(() async {
    final params = _range(messId, p);
    final (totals, info) = await (
      _client.rpc('month_totals', params: params),
      _client.rpc('month_rate_info', params: params),
    ).wait;
    return MonthTotals.fromJson({
      for (final r in [...info as List, ...totals as List])
        ...r as Map<String, dynamic>,
    });
  });

  Future<List<MemberBalance>> balances(String messId, MonthPeriod p) =>
      guard(() async {
        final rows =
            await _client.rpc('member_balances', params: _range(messId, p))
                as List;
        return rows
            .map((r) => MemberBalance.fromJson(r as Map<String, dynamic>))
            .toList();
      });

  Future<List<DayMeals>> dailyMeals(String messId, MonthPeriod p) =>
      _list('daily_meal_totals', _range(messId, p), dayMealsFromJson);

  Future<List<CategoryTotal>> byCategory(String messId, MonthPeriod p) =>
      _list('expense_by_category', _range(messId, p), categoryTotalFromJson);

  Future<List<MonthPoint>> history(String messId, {int months = 6}) => _list(
    'month_history',
    {'p_mess': messId, 'p_months': months, 'p_until': isoDate(today())},
    monthPointFromJson,
  );

  /// Null for a non-member (no row).
  Future<Attention?> attention(String messId, DateTime day) async =>
      (await _list('manager_attention', {
        'p_mess': messId,
        'p_date': isoDate(day),
      }, attentionFromJson)).firstOrNull;

  Future<MessCash?> cash(String messId, MonthPeriod p) async => (await _list(
    'mess_cash',
    _range(messId, p),
    messCashFromJson,
  )).firstOrNull;

  Future<List<MemberTransparency>> transparency(String messId, MonthPeriod p) =>
      _list(
        'member_transparency',
        _range(messId, p),
        memberTransparencyFromJson,
      );

  /// The caller's previous period; null when it had no activity at all.
  Future<LastMonth?> lastMonth(String messId) async => (await _list(
    'my_last_month',
    {'p_mess': messId},
    LastMonth.fromJson,
  )).firstOrNull;

  /// The period waiting to be closed; null when no month has ended.
  Future<MonthStatus?> status(String messId) async => (await _list(
    'month_review',
    {'p_mess': messId},
    MonthStatus.fromJson,
  )).firstOrNull;

  Future<List<MissingMeal>> missingMeals(String messId, MonthPeriod p) =>
      _list('month_missing_meals', _range(messId, p), missingMealFromJson);

  /// True when the opening balance of the period starting [from] is not a
  /// frozen snapshot.
  Future<bool> openingIsProvisional(String messId, DateTime from) =>
      guard(() async {
        final r = await _client.rpc(
          'opening_is_provisional',
          params: {'p_mess': messId, 'p_from': isoDate(from)},
        );
        return r == true;
      });

  /// Pending deposits and bazar requests dated in `[from, to)`.
  Future<PendingItems> pendingItems(
    String messId,
    DateTime from,
    DateTime to,
  ) async =>
      (await _list('month_pending_items', {
        'p_mess': messId,
        'p_from': isoDate(from),
        'p_to': isoDate(to),
      }, pendingItemsFromJson)).firstOrNull ??
      (deposits: 0, bazarRequests: 0);

  Future<List<T>> _list<T>(
    String fn,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic>) parse,
  ) => guard(() async {
    final rows = await _client.rpc(fn, params: params) as List;
    return [for (final r in rows) parse(r as Map<String, dynamic>)];
  });

  Map<String, dynamic> _range(String messId, MonthPeriod p) => {
    'p_mess': messId,
    'p_from': isoDate(p.start),
    'p_to': isoDate(p.end),
  };
}
