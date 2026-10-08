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
    final rows =
        await _client.rpc('month_totals', params: _range(messId, p)) as List;
    return MonthTotals.fromJson(rows.single as Map<String, dynamic>);
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

  Map<String, dynamic> _range(String messId, MonthPeriod p) => {
    'p_mess': messId,
    'p_from': isoDate(p.start),
    'p_to': isoDate(p.end),
  };
}
