import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/widgets/widgets.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import 'common.dart';

String statLabel(AppLocalizations l, String key) => switch (key) {
  'users_total' => l.adminStatUsersTotal,
  'users_7d' => l.adminStatUsers7d,
  'messes_total' => l.adminStatMessesTotal,
  'messes_active_7d' => l.adminStatMessesActive7d,
  'meals_7d' => l.adminStatMeals7d,
  'bazars_7d' => l.adminStatBazars7d,
  'ai_calls_7d' => l.adminStatAiCalls7d,
  'suspended_messes' => l.adminStatSuspendedMesses,
  'deletion_pending' => l.adminStatDeletionPending,
  _ => key,
};

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final stats = ref.watch(adminStatsProvider);
    return stats.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: adminErrorText(context, e),
        onRetry: () => ref.invalidate(adminStatsProvider),
      ),
      data: (s) => AdminPage(
        title: l.adminNavDashboard,
        actions: [
          IconButton(
            tooltip: l.retry,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(adminAiUsageProvider);
            },
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.xl,
          children: [
            Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.md,
              children: [
                for (final k in AdminStats.keys)
                  SizedBox(
                    width: 200,
                    child: AppCard(
                      child: Figure(
                        label: statLabel(l, k),
                        value: NumberFormat.decimalPattern(
                          Localizations.localeOf(context).toString(),
                        ).format(s[k]),
                      ),
                    ),
                  ),
              ],
            ),
            const _AiUsageCard(),
          ],
        ),
      ),
    );
  }
}

class _AiUsageCard extends ConsumerWidget {
  const _AiUsageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final usage = ref.watch(adminAiUsageProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Text(l.adminAiUsage30d, style: text.titleMedium),
          SizedBox(
            height: 220,
            child: usage.when(
              loading: () => const LoadingView(rows: 1),
              error: (e, _) => ErrorView(
                message: adminErrorText(context, e),
                onRetry: () => ref.invalidate(adminAiUsageProvider),
              ),
              data: (rows) {
                final days = callsPerDay(rows);
                if (days.isEmpty) {
                  return EmptyView(message: l.adminAiUsageEmpty);
                }
                final top = days
                    .map((d) => d.calls)
                    .reduce((a, b) => a > b ? a : b);
                return BarChart(
                  BarChartData(
                    maxY: top * 1.15 + 1,
                    minY: 0,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => p.ink,
                        getTooltipItem: (g, _, rod, _) => BarTooltipItem(
                          '${DateFormat.MMMd().format(days[g.x].day)}: ${rod.toY.toInt()}',
                          TextStyle(color: p.onInk),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, meta) =>
                              Text(meta.formattedValue, style: text.labelSmall),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            // Label roughly every 5th day to avoid overlap.
                            if (i % 5 != 0 || i >= days.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              DateFormat.Md().format(days[i].day),
                              style: text.labelSmall,
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < days.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: days[i].calls.toDouble(),
                              width: 8,
                              color: p.ink,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DeletionQueuePage extends ConsumerWidget {
  const DeletionQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ref
        .watch(deletionQueueProvider)
        .when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: adminErrorText(context, e),
            onRetry: () => ref.invalidate(deletionQueueProvider),
          ),
          data: (rows) => AdminPage(
            title: l.adminNavDeletion,
            actions: [
              IconButton(
                tooltip: l.retry,
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(deletionQueueProvider),
              ),
            ],
            child: rows.isEmpty
                ? EmptyView(
                    message: l.adminDeletionEmpty,
                    icon: Icons.check_circle_outline,
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(l.adminUserId)),
                        DataColumn(label: Text(l.adminRequestedAt)),
                        DataColumn(label: Text(l.adminProcessedAt)),
                        DataColumn(label: Text(l.adminLastError)),
                      ],
                      rows: [
                        for (final r in rows)
                          DataRow(
                            cells: [
                              DataCell(SelectableText(r.userId)),
                              DataCell(Text(fmtDate(context, r.requestedAt))),
                              DataCell(Text(fmtDate(context, r.processedAt))),
                              DataCell(
                                Text(
                                  r.lastError ?? '—',
                                  style: r.lastError == null
                                      ? null
                                      : TextStyle(color: context.palette.due),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        );
  }
}
