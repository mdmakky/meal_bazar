import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../month/application/month_providers.dart';
import '../../month/domain/month.dart';
import '../application/meal_providers.dart';
import '../domain/meal.dart';
import 'meal_widgets.dart';

/// The month at a glance: total meals and rate (SQL), then meals per member.
class MealsScreen extends ConsumerWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null) return const Scaffold(body: LoadingView());

    final totalsAsync = ref.watch(monthTotalsProvider(messId));
    final balancesAsync = ref.watch(memberBalancesProvider(messId));
    final period = ref.watch(currentPeriodProvider(messId)).value;
    final guests = ref.watch(guestMealsProvider(messId)).value ?? const {};

    final Widget body;
    final error = [
      if (!totalsAsync.hasValue) totalsAsync.error,
      if (!balancesAsync.hasValue) balancesAsync.error,
    ].nonNulls.firstOrNull;
    if (error != null) {
      body = ErrorView(
        message: failureText(context, error),
        onRetry: () {
          ref.invalidate(currentPeriodProvider(messId));
          ref.invalidate(monthTotalsProvider(messId));
          ref.invalidate(memberBalancesProvider(messId));
        },
      );
    } else if (!totalsAsync.hasValue || !balancesAsync.hasValue) {
      body = const LoadingView(rows: 4);
    } else {
      final t = totalsAsync.value!;
      final bn = bnDigits(context);
      final text = Theme.of(context).textTheme;
      final p = context.palette;
      final rows = balancesAsync.value!.where((b) => b.meals > 0).toList()
        ..sort((a, b) => b.meals.compareTo(a.meals));
      final locale = Localizations.localeOf(context).languageCode;
      String date(DateTime d) =>
          Fmt.dateLong(d, locale: locale, banglaDigits: bn);

      body = ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.xl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.gutter),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.lg,
              children: [
                Expanded(
                  child: Figure(
                    label: l.mealsTotalLabel,
                    value: decimal(t.totalMeals, bangla: bn),
                    proof: period == null
                        ? null
                        : l.mealsPeriod(
                            date(period.start),
                            // The period end is exclusive.
                            date(
                              period.end.subtract(const Duration(hours: 12)),
                            ),
                          ),
                    initiallyExpanded: true,
                  ),
                ),
                Expanded(
                  child: t.unallocatedFood
                      ? Text(
                          l.todayRateUnallocated(
                            Fmt.money(t.foodTotal, banglaDigits: bn),
                          ),
                          style: text.bodyMedium?.copyWith(color: p.warning),
                        )
                      : Figure(
                          label: l.todayRateLabel,
                          value: Fmt.money(t.mealRate, banglaDigits: bn),
                          proof: l.todayRateProof(
                            Fmt.money(t.foodTotal, banglaDigits: bn),
                            decimal(t.totalMeals, bangla: bn),
                          ),
                          initiallyExpanded: true,
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.xl,
              AppSpace.gutter,
              AppSpace.md,
            ),
            child: Text(l.mealsByMember, style: text.titleMedium),
          ),
          if (rows.isEmpty)
            EmptyView(icon: Icons.restaurant_outlined, message: l.mealsEmpty)
          else ...[
            const Divider(),
            for (final b in rows) ...[
              ListTile(
                minTileHeight: AppSize.touch + AppSpace.md,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.gutter,
                ),
                title: Text(b.displayName, style: text.titleSmall),
                subtitle: (guests[b.memberId] ?? 0) > 0
                    ? Text(
                        l.mealsGuestNote(
                          decimal(guests[b.memberId]!, bangla: bn),
                        ),
                      )
                    : null,
                trailing: Text(
                  Fmt.meals(b.meals, banglaDigits: bn),
                  style: text.titleMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                onTap: period == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MemberMealsScreen(
                            messId: messId,
                            memberId: b.memberId,
                            name: b.displayName,
                            meals: b.meals,
                            period: period,
                          ),
                        ),
                      ),
              ),
              const Divider(),
            ],
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.mealsTitle)),
      body: body,
    );
  }
}

/// One member's period, day by day, newest first. Read-only.
class MemberMealsScreen extends ConsumerWidget {
  const MemberMealsScreen({
    super.key,
    required this.messId,
    required this.memberId,
    required this.name,
    required this.meals,
    required this.period,
  });

  final String messId;
  final String memberId;
  final String name;

  /// Billable, from SQL `member_balances`.
  final double meals;
  final MonthPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = (
      messId: messId,
      from: period.start,
      to: period.end,
      memberId: memberId,
    );
    final entriesAsync = ref.watch(rangeEntriesProvider(range));
    final typesAsync = ref.watch(mealTypesProvider(messId));

    final error = [
      if (!entriesAsync.hasValue) entriesAsync.error,
      if (!typesAsync.hasValue) typesAsync.error,
    ].nonNulls.firstOrNull;

    final Widget body;
    if (error != null) {
      body = ErrorView(
        message: failureText(context, error),
        onRetry: () {
          ref.invalidate(rangeEntriesProvider(range));
          ref.invalidate(mealTypesProvider(messId));
        },
      );
    } else if (!entriesAsync.hasValue || !typesAsync.hasValue) {
      body = const LoadingView(rows: 6);
    } else {
      body = _DayList(
        name: name,
        meals: meals,
        entries: entriesAsync.value!,
        types: typesAsync.value!,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: body,
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({
    required this.name,
    required this.meals,
    required this.entries,
    required this.types,
  });

  final String name;
  final double meals;
  final List<MealEntry> entries;
  final List<MealType> types;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final bn = bnDigits(context);
    final locale = Localizations.localeOf(context).languageCode;
    if (entries.isEmpty) {
      return EmptyView(
        icon: Icons.restaurant_outlined,
        message: l.mealsMemberEmpty(name),
      );
    }
    final byDay = <DateTime, Map<String, MealEntry>>{};
    for (final e in entries) {
      (byDay[dayOnly(e.date)] ??= {})[e.mealTypeId] = e;
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final shown = types
        .where((t) => t.enabled || entries.any((e) => e.mealTypeId == t.id))
        .toList();
    final now = today();
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpace.xl),
      itemCount: days.length + 1,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.lg,
              AppSpace.gutter,
              AppSpace.sm,
            ),
            child: Row(
              spacing: AppSpace.xs,
              children: [
                Expanded(
                  child: Text(
                    l.mealsMemberTotal(decimal(meals, bangla: bn)),
                    style: text.titleMedium,
                  ),
                ),
                for (final t in shown)
                  SizedBox(
                    width: AppSize.mealCellWidth,
                    child: Text(
                      t.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium,
                    ),
                  ),
              ],
            ),
          );
        }
        final d = days[i - 1];
        final row = byDay[d]!;
        final total = row.values.fold(0.0, (s, e) => s + e.people);
        final date = Fmt.dateLong(d, locale: locale, banglaDigits: bn);
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.gutter,
            vertical: AppSpace.xs,
          ),
          child: Row(
            spacing: AppSpace.xs,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: text.titleSmall),
                    Text(
                      Fmt.meals(total, banglaDigits: bn),
                      style: text.labelSmall?.copyWith(
                        color: p.inkTertiary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              for (final t in shown)
                MealCell(
                  label: '$date ${t.name}',
                  count: row[t.id]?.count ?? 0,
                  guests: row[t.id]?.guestCount ?? 0,
                  off: row[t.id]?.isOff ?? false,
                  today: d == now,
                  banglaDigits: bn,
                ),
            ],
          ),
        );
      },
    );
  }
}
