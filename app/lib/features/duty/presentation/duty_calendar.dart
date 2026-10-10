import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/ids.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
import '../../money/presentation/money_sheets.dart' show longDate;
import '../application/duty_providers.dart';
import '../domain/duty.dart';

/// The month as a calendar: who goes on which day at a glance. A manager
/// taps any day to choose who does the bazar (one person or several); a
/// member taps to see who is on duty.
class DutyCalendar extends ConsumerWidget {
  const DutyCalendar({
    super.key,
    required this.messId,
    required this.month,
    required this.duties,
    required this.names,
    required this.isManager,
  });

  final String messId;
  final DateTime month;
  final List<BazarDuty> duties;
  final Map<String, String> names;
  final bool isManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final loc = MaterialLocalizations.of(context);
    final bn = l.localeName == 'bn';
    final days = DateTime(month.year, month.month + 1, 0).day;
    final first = loc.firstDayOfWeekIndex; // 0 = Sunday
    final lead =
        (DateTime(month.year, month.month).weekday % 7 - first + 7) % 7;
    final t = today();
    final byDay = <int, List<BazarDuty>>{};
    for (final d in duties) {
      byDay.putIfAbsent(d.date.day, () => []).add(d);
    }
    final cells = lead + days;
    final rows = (cells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: AppCard.raised(
        padding: const EdgeInsets.all(AppSpace.sm),
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        loc.narrowWeekdays[(first + i) % 7],
                        style: text.labelSmall?.copyWith(color: p.inkTertiary),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            for (var r = 0; r < rows; r++)
              Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final day = r * 7 + c - lead + 1;
                          if (day < 1 || day > days) {
                            return const SizedBox(height: _cell);
                          }
                          final date = DateTime(month.year, month.month, day);
                          final here = byDay[day] ?? const <BazarDuty>[];
                          return _DayCell(
                            key: Key('duty-day-$day'),
                            label: Fmt.digits('$day', bangla: bn),
                            isToday: date == t,
                            past: date.isBefore(t),
                            duties: here,
                            names: names,
                            onTap: () => AppSheet.show<void>(
                              context,
                              title: longDate(context, date),
                              child: DutyDaySheet(
                                messId: messId,
                                date: date,
                                month: month,
                                isManager: isManager,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            if (isManager)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: Text(
                  l.dutyCalendarHint,
                  style: text.bodySmall?.copyWith(color: p.inkTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const _cell = 58.0;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.label,
    required this.isToday,
    required this.past,
    required this.duties,
    required this.names,
    required this.onTap,
  });

  final String label;
  final bool isToday;
  final bool past;
  final List<BazarDuty> duties;
  final Map<String, String> names;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    String initial(BazarDuty d) {
      final n = names[d.memberId] ?? '';
      return n.isEmpty ? '?' : n.characters.first;
    }

    return Semantics(
      button: true,
      label: [
        label,
        for (final d in duties) names[d.memberId] ?? '',
      ].join(', '),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: DutyCalendar._cell,
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: isToday ? p.accentSoft : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: isToday ? Border.all(color: p.accent) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 3,
            children: [
              Text(
                label,
                style: text.labelMedium?.copyWith(
                  color: past && !isToday ? p.inkTertiary : p.ink,
                  fontWeight: isToday ? FontWeight.w700 : null,
                ),
              ),
              if (duties.isEmpty)
                const SizedBox(height: 18)
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 2,
                  children: [
                    for (final d in duties.take(2))
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d.done ? p.accent : p.surfaceMuted,
                        ),
                        child: d.done
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Color(0xFF141413),
                              )
                            : Text(
                                initial(d),
                                style: text.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: p.ink,
                                ),
                              ),
                      ),
                    if (duties.length > 2)
                      Text(
                        '+${duties.length - 2}',
                        style: text.labelSmall?.copyWith(fontSize: 10),
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

/// One day: a manager ticks who does the bazar (each tap saves at once);
/// a member just sees who is on duty.
class DutyDaySheet extends ConsumerStatefulWidget {
  const DutyDaySheet({
    super.key,
    required this.messId,
    required this.date,
    required this.month,
    required this.isManager,
  });

  final String messId;
  final DateTime date;
  final DateTime month;
  final bool isManager;

  @override
  ConsumerState<DutyDaySheet> createState() => _DutyDaySheetState();
}

class _DutyDaySheetState extends ConsumerState<DutyDaySheet> {
  var _busy = false;

  Future<void> _toggle(Member m, BazarDuty? existing) async {
    setState(() => _busy = true);
    try {
      final c = ref.read(dutyControllerProvider);
      if (existing != null) {
        await c.delete(existing);
      } else {
        await c.save(
          BazarDuty(
            id: uuidV4(),
            messId: widget.messId,
            date: widget.date,
            memberId: m.id,
          ),
        );
      }
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = widget.month;
    final key = (widget.messId, m, DateTime(m.year, m.month + 1, 0));
    final duties = (ref.watch(dutiesProvider(key)).value ?? const <BazarDuty>[])
        .where((d) => d.date == widget.date)
        .toList();
    final members = (ref.watch(membersProvider(widget.messId)).value ?? [])
        .where(
          (x) =>
              x.status == MemberStatus.active ||
              duties.any((d) => d.memberId == x.id),
        )
        .toList();
    BazarDuty? dutyOf(Member x) =>
        duties.where((d) => d.memberId == x.id).firstOrNull;

    if (!widget.isManager) {
      final on = [
        for (final x in members)
          if (dutyOf(x) != null) x,
      ];
      return Text(
        on.isEmpty ? l.dutyNobody : on.map((x) => x.displayName).join(', '),
        style: Theme.of(context).textTheme.titleMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.md,
      children: [
        Text(l.dutyDayPick, style: Theme.of(context).textTheme.bodyMedium),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final x in members)
              FilterChip(
                key: Key('duty-chip-${x.displayName}'),
                label: Text(x.displayName),
                selected: dutyOf(x) != null,
                onSelected: _busy ? null : (_) => _toggle(x, dutyOf(x)),
              ),
          ],
        ),
      ],
    );
  }
}
