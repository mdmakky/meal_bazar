import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
import '../../money/presentation/money_sheets.dart' show longDate, shortDate;
import '../application/duty_providers.dart';
import '../domain/duty.dart';

/// Member id → display name for the current mess.
Map<String, String> _names(WidgetRef ref, String messId) => {
  for (final m in ref.watch(membersProvider(messId)).value ?? const <Member>[])
    m.id: m.displayName,
};

/// "বাজারের পালা": the month's roster. Managers build and edit it; the
/// assigned member ticks their own day done.
class DutyScreen extends ConsumerStatefulWidget {
  const DutyScreen({super.key});

  @override
  ConsumerState<DutyScreen> createState() => _DutyScreenState();
}

class _DutyScreenState extends ConsumerState<DutyScreen> {
  var _month = DateTime(today().year, today().month);

  Future<void> _generate(String messId) async {
    final l = AppLocalizations.of(context);
    final members = (ref.read(membersProvider(messId)).value ?? const [])
        .where((m) => m.status == MemberStatus.active)
        .toList();
    final r = await AppSheet.show<DutyRotation>(
      context,
      title: l.dutyGenerate,
      child: RotationForm(members: members),
    );
    if (r == null || !mounted) return;
    try {
      final n = await ref.read(dutyControllerProvider).generate(messId, r);
      if (mounted) {
        showSnack(
          context,
          l.dutyCreated(Fmt.digits('$n', bangla: l.localeName == 'bn')),
        );
      }
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final isManager = ref.watch(amIManagerProvider);

    final Widget body;
    if (messId == null) {
      body = EmptyView(message: l.emptyGeneric);
    } else {
      final key = (messId, _month, DateTime(_month.year, _month.month + 1, 0));
      final monthLabel = longDate(context, _month);
      body = Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: l.monthPrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
              ),
              Text(
                monthLabel.substring(monthLabel.indexOf(' ') + 1),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                tooltip: l.dutyNextMonth,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
              ),
            ],
          ),
          const Divider(height: AppSize.hairline),
          Expanded(
            child: switch (ref.watch(dutiesProvider(key))) {
              AsyncValue(:final value?) => _DutyList(
                messId: messId,
                duties: value,
                isManager: isManager,
                onGenerate: () => _generate(messId),
              ),
              AsyncValue(:final error?) => ErrorView(
                message: failureText(context, error),
                onRetry: () => ref.invalidate(dutiesProvider(key)),
              ),
              _ => const LoadingView(),
            },
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.dutyTitle)),
      body: body,
      bottomNavigationBar: messId == null || !isManager
          ? null
          : BottomAction(
              children: [
                AppButton(
                  label: l.dutyGenerate,
                  icon: Icons.autorenew,
                  onPressed: () => _generate(messId),
                ),
              ],
            ),
    );
  }
}

class _DutyList extends ConsumerWidget {
  const _DutyList({
    required this.messId,
    required this.duties,
    required this.isManager,
    required this.onGenerate,
  });

  final String messId;
  final List<BazarDuty> duties;
  final bool isManager;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final me = ref.watch(currentMembershipProvider)?.member.id;
    final t = today();
    final upcoming = me == null
        ? const <BazarDuty>[]
        : (ref
                      .watch(
                        dutiesProvider((
                          messId,
                          t,
                          DateTime(t.year, t.month + 2, t.day),
                        )),
                      )
                      .value ??
                  const <BazarDuty>[])
              .where((d) => d.memberId == me && !d.done)
              .take(3)
              .toList();

    Widget tile(BazarDuty d) => DutyTile(
      duty: d,
      names: _names(ref, messId),
      canTick: isManager || d.memberId == me,
      onTap: isManager ? () => _edit(context, d) : null,
    );

    return ListView(
      children: [
        if (upcoming.isNotEmpty) ...[
          SectionTitle(l.dutyMyUpcoming),
          for (final d in upcoming) ...[
            tile(d),
            const Divider(height: AppSize.hairline),
          ],
          SectionTitle(l.dutyThisMonth),
        ],
        if (duties.isEmpty)
          EmptyView(
            message: l.dutyEmpty,
            icon: Icons.shopping_basket_outlined,
            actionLabel: isManager ? l.dutyGenerate : null,
            onAction: isManager ? onGenerate : null,
          ),
        for (final d in duties) ...[
          tile(d),
          const Divider(height: AppSize.hairline),
        ],
      ],
    );
  }

  Future<void> _edit(BuildContext context, BazarDuty d) => AppSheet.show<void>(
    context,
    title: AppLocalizations.of(context).dutyEditTitle,
    child: EditDutyForm(duty: d),
  );
}

/// One day: date, who, and the done tick.
class DutyTile extends ConsumerWidget {
  const DutyTile({
    super.key,
    required this.duty,
    required this.names,
    required this.canTick,
    this.onTap,
  });

  final BazarDuty duty;
  final Map<String, String> names;
  final bool canTick;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final note = duty.note;
    return ListTile(
      minTileHeight: AppSize.touch + AppSpace.md,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      tileColor: duty.date == today() ? p.accentSoft : null,
      title: Text(
        names[duty.memberId] ?? '',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        [
          shortDate(context, duty.date),
          if (note != null && note.isNotEmpty) note,
        ].join(' · '),
      ),
      trailing: Checkbox(
        value: duty.done,
        semanticLabel: l.dutyDone,
        onChanged: canTick
            ? (v) async {
                try {
                  await ref
                      .read(dutyControllerProvider)
                      .setDone(duty, v ?? false);
                } catch (e) {
                  if (context.mounted) showFailure(context, e);
                }
              }
            : null,
      ),
      onTap: onTap,
    );
  }
}

/// Members in tap order, start date, every N days, how many days.
class RotationForm extends StatefulWidget {
  const RotationForm({super.key, required this.members});

  final List<Member> members;

  @override
  State<RotationForm> createState() => _RotationFormState();
}

class _RotationFormState extends State<RotationForm> {
  final _form = GlobalKey<FormState>();
  final _days = TextEditingController(text: '30');
  final _order = <String>[];
  var _from = today();
  var _every = 1;
  var _showPickError = false;

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _showPickError = _order.isEmpty);
    if (!_form.currentState!.validate() || _order.isEmpty) return;
    Navigator.pop(
      context,
      DutyRotation(
        memberIds: List.of(_order),
        from: _from,
        days: int.parse(_days.text),
        every: _every,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bn = l.localeName == 'bn';
    final text = Theme.of(context).textTheme;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.lg,
        children: [
          Text(l.dutyMembersLabel, style: text.bodyMedium),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final m in widget.members)
                FilterChip(
                  label: Text(
                    _order.contains(m.id)
                        ? '${Fmt.digits('${_order.indexOf(m.id) + 1}', bangla: bn)}. ${m.displayName}'
                        : m.displayName,
                  ),
                  selected: _order.contains(m.id),
                  onSelected: (on) => setState(() {
                    on ? _order.add(m.id) : _order.remove(m.id);
                    _showPickError = false;
                  }),
                ),
            ],
          ),
          if (_showPickError)
            Text(
              l.dutyPickMembers,
              style: text.bodyMedium?.copyWith(color: context.palette.due),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: AppSize.touch,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(l.dutyStart),
            trailing: Text(longDate(context, _from), style: text.titleSmall),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _from,
                firstDate: DateTime(2020),
                lastDate: today().add(const Duration(days: 366)),
              );
              if (d != null) setState(() => _from = dayOnly(d));
            },
          ),
          DropdownButtonFormField<int>(
            initialValue: _every,
            decoration: InputDecoration(labelText: l.dutyEveryLabel),
            items: [
              for (var n = 1; n <= 7; n++)
                DropdownMenuItem(
                  value: n,
                  child: Text(l.dutyEvery(Fmt.digits('$n', bangla: bn))),
                ),
            ],
            onChanged: (n) => setState(() => _every = n ?? 1),
          ),
          TextFormField(
            controller: _days,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l.dutyDays),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 1 || n > 366 ? l.dutyDaysInvalid : null;
            },
          ),
          AppButton(label: l.dutyGenerate, onPressed: _submit),
        ],
      ),
    );
  }
}

/// Manager: swap who does a day, move it, add a note, or delete it.
class EditDutyForm extends ConsumerStatefulWidget {
  const EditDutyForm({super.key, required this.duty});

  final BazarDuty duty;

  @override
  ConsumerState<EditDutyForm> createState() => _EditDutyFormState();
}

class _EditDutyFormState extends ConsumerState<EditDutyForm> {
  late var _member = widget.duty.memberId;
  late var _date = widget.duty.date;
  late final _note = TextEditingController(text: widget.duty.note);
  var _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.dutyDeleteConfirm,
      body: shortDate(context, widget.duty.date),
      action: l.delete,
    );
    if (ok) {
      await _run(() => ref.read(dutyControllerProvider).delete(widget.duty));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final members = ref.watch(membersProvider(widget.duty.messId)).value ?? [];
    final choices = members
        .where((m) => m.status == MemberStatus.active || m.id == _member)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.lg,
      children: [
        DropdownButtonFormField<String>(
          initialValue: choices.any((m) => m.id == _member) ? _member : null,
          decoration: InputDecoration(labelText: l.dutyMember),
          items: [
            for (final m in choices)
              DropdownMenuItem(value: m.id, child: Text(m.displayName)),
          ],
          onChanged: (id) => setState(() => _member = id ?? _member),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: AppSize.touch,
          leading: const Icon(Icons.calendar_today_outlined),
          title: Text(longDate(context, _date)),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2020),
              lastDate: today().add(const Duration(days: 366)),
            );
            if (d != null) setState(() => _date = dayOnly(d));
          },
        ),
        TextField(
          controller: _note,
          maxLength: 200,
          decoration: InputDecoration(labelText: l.dutyNote),
        ),
        Row(
          spacing: AppSpace.sm,
          children: [
            Expanded(
              child: AppButton(
                label: l.delete,
                variant: AppButtonVariant.secondary,
                onPressed: _busy ? null : _delete,
              ),
            ),
            Expanded(
              child: AppButton(
                label: l.save,
                loading: _busy,
                onPressed: () => _run(
                  () => ref
                      .read(dutyControllerProvider)
                      .save(
                        BazarDuty(
                          id: widget.duty.id,
                          messId: widget.duty.messId,
                          date: _date,
                          memberId: _member,
                          note: _note.text.trim().isEmpty
                              ? null
                              : _note.text.trim(),
                          done: widget.duty.done,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
