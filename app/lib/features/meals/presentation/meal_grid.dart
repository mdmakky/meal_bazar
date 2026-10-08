import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/db/db.dart';
import '../../../core/db/sync.dart';
import '../../../core/errors.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
import '../../today/application/day_grid.dart';
import '../application/meal_providers.dart';
import '../domain/meal.dart';
import 'meal_widgets.dart';

/// Active, joined and not yet left on [day].
bool presentOn(Member m, DateTime day) =>
    m.status == MemberStatus.active &&
    !m.joinedOn.isAfter(day) &&
    (m.leftOn == null || day.isBefore(m.leftOn!));

/// Grid rows: members present that day, plus anyone who already has a row.
/// Columns: enabled types, plus disabled ones that still have rows that day.
({List<Member> rows, List<MealType> types}) gridShape(
  List<Member> members,
  List<MealType> types,
  Iterable<MealEntry> entries,
  DateTime day,
) {
  final usedMembers = {for (final e in entries) e.memberId};
  final usedTypes = {for (final e in entries) e.mealTypeId};
  return (
    rows: [
      for (final m in members)
        if (presentOn(m, day) ||
            (m.status != MemberStatus.pending && usedMembers.contains(m.id)))
          m,
    ],
    types: [
      for (final t in types)
        if (t.enabled || usedTypes.contains(t.id)) t,
    ],
  );
}

/// My member id when I am a plain active member, else null.
String? plainMemberId(WidgetRef ref) {
  final me = ref.watch(currentMembershipProvider)?.member;
  return !ref.watch(amIManagerProvider) && me?.status == MemberStatus.active
      ? me!.id
      : null;
}

/// My member id while I may still switch [day]'s meals off, else null.
String? ownOffId(WidgetRef ref, DateTime day) {
  final myId = plainMemberId(ref);
  final mess = ref.watch(currentMessProvider);
  if (myId == null || mess == null) return null;
  final open = ref
      .watch(nowProvider)()
      .isBefore(mealOffDeadline(day, mess.mealOffCutoff));
  return open ? myId : null;
}

MealEntry entryOrZero(
  Map<String, MealEntry>? grid,
  MessDay dayKey,
  String memberId,
  String typeId,
) =>
    grid?[cellKey(memberId, typeId)] ??
    MealEntry(
      memberId: memberId,
      mealTypeId: typeId,
      date: dayKey.day,
      count: 0,
    );

/// Optimistic save; on failure the cell has reverted, so just say why.
Future<bool> putEntry(
  BuildContext context,
  WidgetRef ref,
  MessDay dayKey,
  MealEntry e, {
  bool own = false,
}) async {
  try {
    await ref.read(dayGridProvider(dayKey).notifier).put(e, own: own);
    return true;
  } catch (err) {
    if (context.mounted) showFailure(context, err);
    return false;
  }
}

/// Member, then meal type (skipped when there is only one enabled).
Future<MealEntry?> pickCell(
  BuildContext context,
  WidgetRef ref,
  MessDay dayKey,
  List<Member> members,
  List<MealType> types,
) async {
  final l = AppLocalizations.of(context);
  final active = types.where((t) => t.enabled).toList();
  final member = await pickOne<Member>(
    context,
    title: l.todayPickMember,
    options: [for (final m in members) (m, m.displayName)],
  );
  if (member == null || !context.mounted || active.isEmpty) return null;
  final type = active.length == 1
      ? active.single
      : await pickOne<MealType>(
          context,
          title: l.todayPickMealType,
          options: [for (final t in active) (t, t.name)],
        );
  if (type == null) return null;
  return entryOrZero(
    ref.read(dayGridProvider(dayKey)).value,
    dayKey,
    member.id,
    type.id,
  );
}

String _cellTitle(MealEntry e, List<Member> members, List<MealType> types) =>
    '${members.firstWhere((m) => m.id == e.memberId).displayName} · '
    '${types.firstWhere((t) => t.id == e.mealTypeId).name}';

/// Pick a cell, then edit its guests.
Future<void> addGuest(
  BuildContext context,
  WidgetRef ref,
  MessDay dayKey,
  List<Member> members,
  List<MealType> types,
) async {
  final current = await pickCell(context, ref, dayKey, members, types);
  if (current == null || !context.mounted) return;
  final e = await showMealEntrySheet(
    context,
    title: _cellTitle(current, members, types),
    entry: current,
    guestsFirst: true,
  );
  if (e != null && context.mounted) await putEntry(context, ref, dayKey, e);
}

/// Manager: pick a cell and switch it off.
Future<void> markMealOff(
  BuildContext context,
  WidgetRef ref,
  MessDay dayKey,
  List<Member> members,
  List<MealType> types,
) async {
  final l = AppLocalizations.of(context);
  final current = await pickCell(context, ref, dayKey, members, types);
  if (current == null || !context.mounted) return;
  final ok = await putEntry(
    context,
    ref,
    dayKey,
    current.copyWith(isOff: true, count: 0),
  );
  if (ok && context.mounted) {
    final [name, meal] = _cellTitle(current, members, types).split(' · ');
    showSnack(context, l.todayMealOffDone(name, meal));
  }
}

/// Member: pick tomorrow's meal types to have off, then save the changes.
Future<void> offTomorrow(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final mess = ref.read(currentMessProvider);
  final me = ref.read(currentMembershipProvider)?.member.id;
  if (mess == null || me == null) return;
  final tomorrow = dayOnly(today().add(const Duration(days: 1, hours: 2)));
  if (!ref
      .read(nowProvider)()
      .isBefore(mealOffDeadline(tomorrow, mess.mealOffCutoff))) {
    showSnack(context, l.mealOffCutoffPassed);
    return;
  }
  final key = (messId: mess.id, day: tomorrow);
  final Map<String, MealEntry> grid;
  final List<MealType> active;
  try {
    grid = await ref.read(dayGridProvider(key).future);
    active = [
      for (final t in await ref.read(mealTypesProvider(mess.id).future))
        if (t.enabled) t,
    ];
  } catch (e) {
    if (context.mounted) showFailure(context, e);
    return;
  }
  if (!context.mounted) return;
  MealEntry current(MealType t) => entryOrZero(grid, key, me, t.id);
  final off = await _pickOff(context, active, {
    for (final t in active)
      if (current(t).isOff) t.id,
  });
  if (off == null || !context.mounted) return;
  for (final t in active) {
    final e = current(t);
    if (e.isOff == off.contains(t.id)) continue;
    if (!await putEntry(context, ref, key, toggleMealOff(e), own: true)) {
      return;
    }
    if (!context.mounted) return;
  }
  showSnack(context, l.mealOffSaved);
}

/// Checklist of meal types; returns the ids to have off, or null if dismissed.
Future<Set<String>?> _pickOff(
  BuildContext context,
  List<MealType> types,
  Set<String> initial,
) {
  final l = AppLocalizations.of(context);
  final off = {...initial};
  return AppSheet.show<Set<String>>(
    context,
    title: l.mealOffTomorrowTitle,
    actions: [
      Builder(
        builder: (context) => AppButton(
          label: l.mealOffSave,
          onPressed: () => Navigator.pop(context, off),
        ),
      ),
    ],
    child: StatefulBuilder(
      builder: (context, setState) => Column(
        children: [
          for (final t in types)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.name),
              value: off.contains(t.id),
              onChanged: (v) =>
                  setState(() => v == true ? off.add(t.id) : off.remove(t.id)),
            ),
        ],
      ),
    ),
  );
}

/// This mess's worst queue state; a failed write names why and offers retry
/// or discard (the next pull restores the server's value).
class SyncLine extends ConsumerWidget {
  const SyncLine({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ops = [
      for (final o in ref.watch(syncQueueProvider).value ?? const <SyncOp>[])
        if (o.messId == messId) o,
    ];
    final failed = ops.where((o) => o.status == opFailed);
    final error = failed.firstOrNull?.lastError;
    return Column(
      children: [
        SyncBadge(
          state: queueState(ops),
          onRetry: () => ref.read(syncServiceProvider).retryFailed(),
          onDiscard: () async {
            await ref.read(appDbProvider).discard(failed.map((o) => o.id));
            ref.invalidate(dayEntriesProvider);
          },
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            child: Text(
              failureText(
                context,
                AppFailure(
                  FailureKind.values.asNameMap()[error] ?? FailureKind.unknown,
                ),
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}

/// Members: when tomorrow's meals can still be switched off.
class MealOffHint extends StatelessWidget {
  const MealOffHint({super.key, required this.cutoff});

  /// Postgres `time`, e.g. '22:00:00'.
  final String cutoff;

  @override
  Widget build(BuildContext context) {
    final p = cutoff.split(':').map(int.parse).toList();
    // ponytail: copy says "tonight"/pm; fine for evening cutoffs (the default).
    final h = p[0] % 12 == 0 ? 12 : p[0] % 12;
    final time = p[1] == 0 ? '$h' : '$h:${p[1].toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        0,
      ),
      child: Text(
        AppLocalizations.of(
          context,
        ).mealOffHint(Fmt.digits(time, bangla: bnDigits(context))),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Display-only headcount (own + guests, off = 0) of [types] on a day;
/// billing comes from SQL.
double dayPeople(Iterable<MealEntry> entries, Iterable<MealType> types) {
  final ids = {for (final t in types) t.id};
  return entries
      .where((e) => ids.contains(e.mealTypeId))
      .fold(0.0, (s, e) => s + e.people);
}

const _nameWidth = AppSize.gridName;
const _stepTarget = AppSize.stepTarget;
const _stepFace = AppSize.stepFace;
const _valueWidth = AppSize.stepValue;
const _cellWidth = _stepTarget * 2 + _valueWidth;
const _headerHeight = AppSize.gridHeader;
const _rowHeight = AppSize.gridRow;

/// Member × meal type, each cell a compact `− value +` stepper; the last row
/// holds column totals. The name column stays put; the meal columns scroll
/// sideways when they do not fit (3+ types on a 360 dp phone).
class MealStepperGrid extends ConsumerWidget {
  const MealStepperGrid({
    super.key,
    required this.dayKey,
    required this.rows,
    required this.types,
    required this.editable,
    this.ownOffId,
  });

  final MessDay dayKey;
  final List<Member> rows;
  final List<MealType> types;

  /// Manager: steppers, value tap cycles, long press opens the entry sheet.
  final bool editable;

  /// A member before the cutoff: a tap on their own value switches it off/on.
  final String? ownOffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = bnDigits(context);
    final entries =
        ref.watch(dayGridProvider(dayKey)).value?.values ?? const [];
    final line = BoxDecoration(
      border: Border(bottom: BorderSide(color: p.border)),
    );
    final head = BoxDecoration(
      color: p.surfaceMuted,
      border: Border(bottom: BorderSide(color: p.border)),
    );

    Widget nameCell(String s, double h, {TextStyle? style, Decoration? deco}) =>
        Container(
          height: h,
          decoration: deco ?? line,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            s,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style ?? text.titleSmall,
          ),
        );

    final names = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        nameCell(
          l.todayMemberColumn,
          _headerHeight,
          style: text.labelMedium,
          deco: head,
        ),
        for (final m in rows) nameCell(m.displayName, _rowHeight),
        nameCell(l.mealGridTotalRow, _rowHeight, deco: const BoxDecoration()),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        final room = c.maxWidth - _nameWidth;
        final fits = _cellWidth * types.length <= room;
        final colW = fits ? room / types.length : _cellWidth;
        final cells = Column(
          children: [
            Row(
              children: [
                for (final t in types)
                  Container(
                    width: colW,
                    height: _headerHeight,
                    decoration: head,
                    alignment: Alignment.center,
                    child: Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium,
                    ),
                  ),
              ],
            ),
            for (final m in rows)
              Container(
                height: _rowHeight,
                decoration: line,
                child: Row(
                  children: [
                    for (final t in types)
                      SizedBox(
                        width: colW,
                        child: _StepperCell(
                          dayKey: dayKey,
                          member: m,
                          type: t,
                          editable: editable,
                          ownOff: ownOffId == m.id && t.enabled,
                        ),
                      ),
                  ],
                ),
              ),
            SizedBox(
              height: _rowHeight,
              child: Row(
                children: [
                  for (final t in types)
                    SizedBox(
                      width: colW,
                      child: Text(
                        decimal(dayPeople(entries, [t]), bangla: bn),
                        textAlign: TextAlign.center,
                        style: text.titleSmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: _nameWidth, child: names),
            Expanded(
              child: fits
                  ? cells
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: cells,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StepperCell extends ConsumerWidget {
  const _StepperCell({
    required this.dayKey,
    required this.member,
    required this.type,
    required this.editable,
    required this.ownOff,
  });

  final MessDay dayKey;
  final Member member;
  final MealType type;
  final bool editable;
  final bool ownOff;

  MealEntry _current(WidgetRef ref) => entryOrZero(
    ref.read(dayGridProvider(dayKey)).value,
    dayKey,
    member.id,
    type.id,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bn = bnDigits(context);
    final k = cellKey(member.id, type.id);
    final (count, guests, off) = ref.watch(
      dayGridProvider(dayKey).select((a) {
        final e = a.value?[k];
        return (e?.count ?? 0.0, e?.guestCount ?? 0, e?.isOff ?? false);
      }),
    );
    final label = '${member.displayName} ${type.name}';
    final value = off ? '—' : decimal(count, bangla: bn);
    final guestText = '+${Fmt.digits('$guests', bangla: bn)}';
    final spoken = [
      off ? l.mealCellOff : value,
      if (guests > 0) l.mealCellGuests(guestText),
    ].join(', ');

    void put(MealEntry e, {bool own = false}) =>
        putEntry(context, ref, dayKey, e, own: own);

    final VoidCallback? onTap = editable
        ? () => put(cycleMeal(_current(ref)))
        : ownOff
        ? () => put(toggleMealOff(_current(ref)), own: true)
        : null;

    final face = Semantics(
      container: true,
      label: '$label: $spoken',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        onLongPress: editable
            ? () async {
                final e = await showMealEntrySheet(
                  context,
                  title: '${member.displayName} · ${type.name}',
                  entry: _current(ref),
                );
                if (e != null && context.mounted) put(e);
              }
            : null,
        child: SizedBox(
          width: _valueWidth,
          height: _rowHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.valueFade,
                child: Text(
                  value,
                  key: ValueKey(value),
                  maxLines: 1,
                  style: text.titleSmall?.copyWith(
                    color: off || count == 0 ? p.inkTertiary : p.ink,
                    decoration: off ? TextDecoration.lineThrough : null,
                    decorationColor: p.inkTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (guests > 0)
                Text(
                  guestText,
                  style: text.labelSmall?.copyWith(
                    color: p.inkSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!editable) return Center(child: face);
    final now = off ? 0.0 : count;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepButton(
          icon: Icons.remove,
          label: '${l.mealCellDecrease} $label',
          onTap: now <= 0 ? null : () => put(stepMeal(_current(ref), -0.5)),
        ),
        face,
        _StepButton(
          icon: Icons.add,
          label: '${l.mealCellIncrease} $label',
          onTap: now >= 5 ? null : () => put(stepMeal(_current(ref), 0.5)),
        ),
      ],
    );
  }
}

/// A 28 dp circle inside a 40 × 56 dp hit area.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: _stepTarget / 2,
        child: SizedBox(
          width: _stepTarget,
          height: _rowHeight,
          child: Center(
            child: Container(
              width: _stepFace,
              height: _stepFace,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: on ? p.borderStrong : p.border),
              ),
              child: Icon(
                icon,
                size: AppSize.dot * 2,
                color: on ? p.ink : p.inkTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
