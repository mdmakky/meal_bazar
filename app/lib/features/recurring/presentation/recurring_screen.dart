import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/ids.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart';
import '../../money/application/money_providers.dart';
import '../../money/domain/money.dart';
import '../../money/presentation/money_sheets.dart' show splitLabel;
import '../application/recurring_providers.dart';
import '../domain/recurring.dart';

bool _bn(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'bn';

/// Posts this period's bills and says how many in a SnackBar.
Future<void> _apply(BuildContext context, WidgetRef ref, String messId) async {
  final l = AppLocalizations.of(context);
  try {
    final n = await ref.read(recurringControllerProvider).apply(messId);
    if (!context.mounted) return;
    showSnack(
      context,
      n == 0
          ? l.recurringNothingToApply
          : l.recurringApplied(Fmt.digits('$n', bangla: _bn(context))),
    );
  } catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}

/// Manager: the mess's monthly bills — add, edit, switch off, post this month.
class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  var _applying = false;

  Future<void> _edit(String messId, [RecurringExpense? existing]) async {
    final l = AppLocalizations.of(context);
    final bill = await AppSheet.show<RecurringExpense>(
      context,
      title: existing == null ? l.recurringAdd : l.recurringEdit,
      child: _BillForm(messId: messId, existing: existing),
    );
    if (bill != null && mounted) await _save(bill);
  }

  Future<void> _save(RecurringExpense b) async {
    try {
      await ref.read(recurringControllerProvider).saveBill(b);
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _applyNow(String messId) async {
    setState(() => _applying = true);
    await _apply(context, ref, messId);
    if (mounted) setState(() => _applying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final manager = ref.watch(amIManagerProvider);

    final Widget body;
    if (messId == null) {
      body = const LoadingView();
    } else if (!manager) {
      body = EmptyView(
        icon: Icons.lock_outline,
        message: l.recurringManagerOnly,
      );
    } else {
      final async = ref.watch(recurringBillsProvider(messId));
      final cats = {
        for (final c
            in ref.watch(expenseCategoriesProvider(messId)).value ??
                const <ExpenseCategory>[])
          c.id: c.name,
      };
      body = switch (async) {
        AsyncValue(:final value?) when value.isEmpty => EmptyView(
          icon: Icons.event_repeat,
          message: l.recurringEmpty,
        ),
        AsyncValue(:final value?) => _list(messId, value, cats),
        AsyncValue(:final error?) => ErrorView(
          message: failureText(context, error),
          onRetry: () => ref.invalidate(recurringBillsProvider(messId)),
        ),
        _ => const LoadingView(),
      };
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.recurringTitle)),
      body: body,
      bottomNavigationBar: messId == null || !manager
          ? null
          : BottomAction(
              children: [
                AppButton(
                  label: l.recurringApply,
                  icon: Icons.playlist_add_check,
                  loading: _applying,
                  onPressed: () => _applyNow(messId),
                ),
                AppButton(
                  label: l.recurringAdd,
                  icon: Icons.add,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _edit(messId),
                ),
              ],
            ),
    );
  }

  Widget _list(
    String messId,
    List<RecurringExpense> bills,
    Map<String, String> cats,
  ) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final bn = _bn(context);
    return StaggeredList(
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.xl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.gutter),
            child: Text(
              l.recurringHelp,
              style: text.bodyMedium?.copyWith(color: p.inkSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            child: RaisedGroup(
              children: [
                for (final (i, b) in bills.indexed)
                  Stagger(
                    index: i,
                    child: ListTile(
                      minTileHeight: AppSize.touch + AppSpace.md,
                      contentPadding: const EdgeInsets.only(
                        left: AppSpace.lg,
                        right: AppSpace.sm,
                      ),
                      leading: IconTile(
                        Icons.event_repeat,
                        color: b.active ? null : p.inkTertiary,
                      ),
                      title: Text(
                        cats[b.categoryId] ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          color: b.active ? null : p.inkTertiary,
                        ),
                      ),
                      subtitle: Text(
                        '${Fmt.money(b.amount, banglaDigits: bn)} · '
                        '${splitLabel(l, b.split)} · '
                        '${l.recurringDayValue(Fmt.digits('${b.dayOfPeriod}', bangla: bn))}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Semantics(
                        label: l.recurringActive(cats[b.categoryId] ?? ''),
                        child: Switch(
                          value: b.active,
                          onChanged: (v) => _save(b.copyWith(active: v)),
                        ),
                      ),
                      onTap: () => _edit(messId, b),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Add / edit sheet body. Pops the edited bill; the caller saves it.
class _BillForm extends ConsumerStatefulWidget {
  const _BillForm({required this.messId, this.existing});

  final String messId;
  final RecurringExpense? existing;

  @override
  ConsumerState<_BillForm> createState() => _BillFormState();
}

class _BillFormState extends ConsumerState<_BillForm> {
  final _form = GlobalKey<FormState>();
  late final RecurringExpense? _e = widget.existing;
  late final _amount = TextEditingController(
    text: _e == null
        ? ''
        : _e.amount.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
  );
  late final _note = TextEditingController(text: _e?.note);
  late var _category = _e?.categoryId;
  late var _split = _e?.split ?? SplitMethod.equal;
  late var _day = _e?.dayOfPeriod ?? 1;
  var _noCategory = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _noCategory = _category == null);
    if (!_form.currentState!.validate() || _category == null) return;
    final note = _note.text.trim();
    Navigator.pop(
      context,
      RecurringExpense(
        id: _e?.id ?? uuidV4(),
        messId: widget.messId,
        categoryId: _category!,
        amount: parseAmount(_amount.text)!,
        split: _split,
        note: note.isEmpty ? null : note,
        active: _e?.active ?? true,
        dayOfPeriod: _day,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final bn = _bn(context);
    final cats =
        ref.watch(expenseCategoriesProvider(widget.messId)).value ??
        const <ExpenseCategory>[];
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.lg,
        children: [
          TextFormField(
            key: const Key('amount'),
            controller: _amount,
            autofocus: _e == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9০-৯.]')),
            ],
            decoration: InputDecoration(
              labelText: l.moneyAmount,
              prefixText: '৳ ',
            ),
            validator: (v) =>
                parseAmount(v ?? '') == null ? l.moneyAmountInvalid : null,
          ),
          Text(l.expenseCategory, style: text.titleSmall),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final c in cats)
                ChoiceChip(
                  label: Text(c.name),
                  selected: c.id == _category,
                  onSelected: (_) => setState(() {
                    _category = c.id;
                    _split = c.defaultSplit;
                    _noCategory = false;
                  }),
                ),
            ],
          ),
          if (_noCategory)
            Text(
              l.expensePickCategory,
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          Text(l.expenseSplit, style: text.titleSmall),
          SegmentedButton<SplitMethod>(
            showSelectedIcon: false,
            segments: [
              for (final s in SplitMethod.values)
                ButtonSegment(value: s, label: Text(splitLabel(l, s))),
            ],
            selected: {_split},
            onSelectionChanged: (s) => setState(() => _split = s.first),
          ),
          DropdownButtonFormField<int>(
            initialValue: _day,
            decoration: InputDecoration(labelText: l.recurringDay),
            items: [
              for (var d = 1; d <= 28; d++)
                DropdownMenuItem(
                  value: d,
                  child: Text(
                    l.recurringDayValue(Fmt.digits('$d', bangla: bn)),
                  ),
                ),
            ],
            onChanged: (d) => setState(() => _day = d ?? _day),
          ),
          TextFormField(
            controller: _note,
            maxLength: 300,
            decoration: InputDecoration(labelText: l.moneyNote),
          ),
          AppButton(label: l.save, expand: true, onPressed: _submit),
        ],
      ),
    );
  }
}

/// For Home: "N monthly bills not posted yet this month" with a post button.
/// Shows nothing for members, while loading, on error, or when none pending.
class RecurringPromptCard extends ConsumerStatefulWidget {
  const RecurringPromptCard({super.key});

  @override
  ConsumerState<RecurringPromptCard> createState() =>
      _RecurringPromptCardState();
}

class _RecurringPromptCardState extends ConsumerState<RecurringPromptCard> {
  var _applying = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null ||
        !ref.watch(amIManagerProvider) ||
        !ref.featureOn('recurring')) {
      return const SizedBox.shrink();
    }
    final n = ref.watch(pendingRecurringProvider(messId)).value ?? 0;
    if (n == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        0,
      ),
      child: AppCard.raised(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            Row(
              spacing: AppSpace.md,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.palette.surfaceMuted,
                  child: Icon(
                    Icons.event_repeat,
                    size: 20,
                    color: context.palette.ink,
                  ),
                ),
                Expanded(
                  child: Text(
                    l.recurringPending(Fmt.digits('$n', bangla: _bn(context))),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            AppButton(
              label: l.recurringApply,
              variant: AppButtonVariant.secondary,
              loading: _applying,
              onPressed: () async {
                setState(() => _applying = true);
                await _apply(context, ref, messId);
                if (mounted) setState(() => _applying = false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
