import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/ids.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../ai/presentation/ai_entry.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
import '../application/money_providers.dart';
import '../domain/money.dart';

// ── Public entry points (also used by the Today quick actions) ────────────

Future<void> showAddBazarSheet(BuildContext context) => showBazarForm(context);

Future<void> showAddExpenseSheet(BuildContext context) =>
    showExpenseForm(context);

Future<void> showAddDepositSheet(BuildContext context) =>
    showDepositForm(context);

Future<void> showBazarForm(BuildContext context, {Bazar? existing}) {
  final l = AppLocalizations.of(context);
  return _showForm(
    context,
    existing == null ? l.bazarAdd : l.bazarEdit,
    _BazarForm(existing: existing),
  );
}

Future<void> showExpenseForm(BuildContext context, {Expense? existing}) {
  final l = AppLocalizations.of(context);
  return _showForm(
    context,
    existing == null ? l.expenseAdd : l.expenseEdit,
    _ExpenseForm(existing: existing),
  );
}

Future<void> showDepositForm(BuildContext context, {Deposit? existing}) {
  final l = AppLocalizations.of(context);
  return _showForm(
    context,
    existing == null ? l.depositAdd : l.depositEdit,
    _DepositForm(existing: existing),
  );
}

/// The form pops with the snackbar text (saved / deleted).
Future<void> _showForm(BuildContext context, String title, Widget form) async {
  final done = await AppSheet.show<String>(context, title: title, child: form);
  if (done != null && context.mounted) showSnack(context, done);
}

// ── Shared helpers ─────────────────────────────────────────────────────────

bool banglaDigits(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'bn';

String money(BuildContext context, num v) =>
    Fmt.money(v, banglaDigits: banglaDigits(context));

String longDate(BuildContext context, DateTime d) => Fmt.dateLong(
  d,
  locale: Localizations.localeOf(context).languageCode,
  banglaDigits: banglaDigits(context),
);

/// "৮ অক্টোবর": the long date without the year.
String shortDate(BuildContext context, DateTime d) {
  final s = longDate(context, d);
  return s.substring(0, s.lastIndexOf(' '));
}

String methodLabel(AppLocalizations l, PayMethod m) => switch (m) {
  PayMethod.cash => l.depositCash,
  PayMethod.bkash => l.depositBkash,
  PayMethod.nagad => l.depositNagad,
  PayMethod.bank => l.depositBank,
  PayMethod.other => l.depositOther,
};

String splitLabel(AppLocalizations l, SplitMethod s) =>
    s == SplitMethod.meal ? l.expenseSplitMeal : l.expenseSplitEqual;

/// Members who can be picked: everyone except pending and left
/// (plus [keep], so an edit still shows the original pick).
List<Member> _pickable(List<Member> all, [String? keep]) => [
  for (final m in all)
    if (m.id == keep ||
        m.status == MemberStatus.active ||
        m.status == MemberStatus.inactive)
      m,
];

String? _trimmed(TextEditingController c) {
  final s = c.text.trim();
  return s.isEmpty ? null : s;
}

/// Save / delete plumbing with an inline error.
mixin _Submit<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  final formKey = GlobalKey<FormState>();
  var saving = false;
  Object? error;

  Future<void> run(Future<void> Function() action, String done) async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await action();
      if (mounted) Navigator.pop(context, done);
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = e;
        });
      }
    }
  }

  Future<void> save(Future<void> Function() action) async {
    if (!formKey.currentState!.validate()) return;
    await run(action, AppLocalizations.of(context).moneySaved);
  }

  Future<void> delete(Future<void> Function() action) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.moneyDeleteConfirmTitle,
      body: l.moneyDeleteConfirmBody,
      action: l.delete,
    );
    if (ok && mounted) await run(action, l.moneyDeleted);
  }

  /// Error line plus the action row; [onDelete] only when editing.
  Widget footer(VoidCallback onSave, {VoidCallback? onDelete}) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        if (error != null)
          Text(
            failureText(context, error!),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.palette.due),
          ),
        Row(
          spacing: AppSpace.sm,
          children: [
            if (onDelete != null)
              Expanded(
                child: AppButton(
                  label: l.delete,
                  variant: AppButtonVariant.secondary,
                  onPressed: saving ? null : onDelete,
                ),
              ),
            Expanded(
              child: AppButton(
                label: l.moneySave,
                loading: saving,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: context.palette.inkSecondary),
  );
}

/// Wraps a non-text input so the Form can validate it.
class _Required extends StatelessWidget {
  const _Required({
    required this.ok,
    required this.message,
    required this.child,
  });

  final bool Function() ok;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) => FormField<void>(
    validator: (_) => ok() ? null : message,
    builder: (f) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        if (f.hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(
              f.errorText!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.palette.due),
            ),
          ),
      ],
    ),
  );
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    this.autofocus = false,
    this.positive = false,
  });

  final TextEditingController controller;
  final bool autofocus;

  /// Deposits must be > 0; bazar and expenses may be 0.
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextFormField(
      key: const Key('amount'),
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9০-৯.]'))],
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(labelText: l.moneyAmount, prefixText: '৳ '),
      validator: (v) {
        final a = parseAmount(v ?? '');
        if (a == null) return l.moneyAmountInvalid;
        if (positive && a == 0) return l.depositAmountPositive;
        return null;
      },
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ActionChip(
      avatar: const Icon(Icons.calendar_today_outlined),
      label: Text(longDate(context, value)),
      tooltip: AppLocalizations.of(context).moneyChangeDate,
      onPressed: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: today().add(const Duration(days: 31)),
        );
        if (d != null) onChanged(dayOnly(d));
      },
    ),
  );
}

class _MemberChips extends ConsumerWidget {
  const _MemberChips({
    required this.messId,
    required this.selected,
    required this.onSelected,
  });

  final String messId;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = _pickable(
      ref.watch(membersProvider(messId)).value ?? const [],
      selected,
    );
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final m in members)
          ChoiceChip(
            label: Text(m.displayName),
            selected: m.id == selected,
            onSelected: (_) => onSelected(m.id),
          ),
      ],
    );
  }
}

/// Mess fund vs own pocket (→ `paid_by_member_id`).
class _PaidFrom extends StatelessWidget {
  const _PaidFrom({
    required this.messId,
    required this.pocket,
    required this.paidBy,
    required this.onPocket,
    required this.onPaidBy,
  });

  final String messId;
  final bool pocket;
  final String? paidBy;
  final ValueChanged<bool> onPocket;
  final ValueChanged<String> onPaidBy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        _Label(l.moneyPaidFrom),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(l.moneyPaidFund)),
            ButtonSegment(value: true, label: Text(l.moneyPaidPocket)),
          ],
          selected: {pocket},
          onSelectionChanged: (s) => onPocket(s.first),
        ),
        if (pocket) ...[
          _Label(l.moneyPaidPocketHelp),
          _Required(
            ok: () => paidBy != null,
            message: l.moneyPickMember,
            child: _MemberChips(
              messId: messId,
              selected: paidBy,
              onSelected: onPaidBy,
            ),
          ),
        ],
      ],
    );
  }
}

/// Reads the current mess; shows a hint when there is none.
class _WithMess extends ConsumerWidget {
  const _WithMess({required this.builder});

  final Widget Function(String messId) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messId = ref.watch(currentMessIdProvider);
    return messId == null
        ? Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.lg),
            child: Text(AppLocalizations.of(context).moneyNoMess),
          )
        : builder(messId);
  }
}

// ── Bazar ─────────────────────────────────────────────────────────────────

class _ItemCtrls {
  _ItemCtrls([BazarItem? i])
    : name = TextEditingController(text: i?.name),
      qty = TextEditingController(text: i?.qty == null ? '' : _num(i!.qty!)),
      unit = TextEditingController(text: i?.unit),
      price = TextEditingController(text: i == null ? '' : _num(i.price));

  final TextEditingController name, qty, unit, price;

  bool get isEmpty =>
      [name, qty, unit, price].every((c) => c.text.trim().isEmpty);

  void dispose() {
    for (final c in [name, qty, unit, price]) {
      c.dispose();
    }
  }
}

/// 1410.5 → "1410.5", 250.0 → "250" (for prefilled fields).
String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

class _BazarForm extends ConsumerStatefulWidget {
  const _BazarForm({this.existing});

  final Bazar? existing;

  @override
  ConsumerState<_BazarForm> createState() => _BazarFormState();
}

class _BazarFormState extends ConsumerState<_BazarForm>
    with _Submit<_BazarForm> {
  late final Bazar? _b = widget.existing;
  late final _amount = TextEditingController(
    text: _b == null ? '' : _num(_b.amount),
  );
  late final _note = TextEditingController(text: _b?.note);
  late var _date = _b?.date ?? today();
  late var _buyer = _b?.buyerMemberId;
  late var _pocket = _b?.paidByMemberId != null;
  late var _paidBy = _b?.paidByMemberId;
  late final _items = [for (final i in _b?.items ?? const []) _ItemCtrls(i)];
  late var _source = _b?.source ?? 'app';

  /// AI reads a receipt or ফর্দ into a draft; the user still reviews and saves.
  Future<void> _scan() async {
    final draft = await scanBazarReceipt(context);
    if (draft == null || !mounted) return;
    setState(() {
      for (final i in _items) {
        i.dispose();
      }
      _items
        ..clear()
        ..addAll([
          for (final d in draft.items)
            _ItemCtrls(
              BazarItem(
                id: '',
                name: d.name,
                price: d.price,
                qty: d.qty,
                unit: d.unit,
              ),
            ),
        ]);
      _amount.text = _num(
        draft.total ?? itemsTotal(draft.items.map((d) => d.price)),
      );
      _source = 'ai';
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  double get _itemsSum =>
      itemsTotal([for (final i in _items) parseAmount(i.price.text) ?? 0]);

  Bazar _build(String messId) => Bazar(
    id: _b?.id ?? uuidV4(),
    messId: messId,
    date: _date,
    amount: parseAmount(_amount.text)!,
    buyerMemberId: _buyer,
    paidByMemberId: _pocket ? _paidBy : null,
    note: _trimmed(_note),
    source: _source,
    items: [
      for (final i in _items)
        if (!i.isEmpty)
          BazarItem(
            id: uuidV4(),
            name: i.name.text.trim(),
            price: parseAmount(i.price.text)!,
            qty: parseAmount(i.qty.text),
            unit: _trimmed(i.unit),
          ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(moneyControllerProvider);
    return _WithMess(
      builder: (messId) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.lg,
          children: [
            if (_b == null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(
                  label: l.bazarScan,
                  icon: Icons.document_scanner_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: saving ? null : _scan,
                ),
              ),
            _AmountField(controller: _amount, autofocus: _b == null),
            _DateChip(
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            _Label(l.bazarBuyer),
            _MemberChips(
              messId: messId,
              selected: _buyer,
              onSelected: (id) => setState(() => _buyer = id),
            ),
            _PaidFrom(
              messId: messId,
              pocket: _pocket,
              paidBy: _paidBy,
              onPocket: (v) => setState(() => _pocket = v),
              onPaidBy: (id) => setState(() => _paidBy = id),
            ),
            _Label(l.bazarItems),
            for (final i in _items) _itemRow(i),
            if (_items.any((i) => !i.isEmpty))
              Row(
                children: [
                  Expanded(
                    child: _Label(l.bazarItemsSum(money(context, _itemsSum))),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _amount.text = _num(_itemsSum)),
                    child: Text(l.bazarUseSum),
                  ),
                ],
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l.bazarAddItem),
                onPressed: () => setState(() => _items.add(_ItemCtrls())),
              ),
            ),
            TextFormField(
              controller: _note,
              maxLength: 300,
              decoration: InputDecoration(labelText: l.moneyNote),
            ),
            footer(
              () => save(() => ctrl.saveBazar(_build(messId))),
              onDelete: _b == null
                  ? null
                  : () => delete(() => ctrl.deleteBazar(_b)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(_ItemCtrls i) {
    final l = AppLocalizations.of(context);
    String? need(String? v) =>
        !i.isEmpty && (v ?? '').trim().isEmpty ? l.bazarItemInvalid : null;
    return Column(
      spacing: AppSpace.sm,
      children: [
        Row(
          spacing: AppSpace.sm,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: i.name,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: l.bazarItemName,
                  counterText: '',
                ),
                validator: need,
              ),
            ),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: i.price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l.bazarItemPrice,
                  prefixText: '৳ ',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    need(v) ??
                    (i.isEmpty || parseAmount(v!) != null
                        ? null
                        : l.moneyAmountInvalid),
              ),
            ),
          ],
        ),
        Row(
          spacing: AppSpace.sm,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: i.qty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: l.bazarItemQty),
                validator: (v) =>
                    (v ?? '').trim().isEmpty || parseAmount(v!) != null
                    ? null
                    : l.moneyAmountInvalid,
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: i.unit,
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: l.bazarItemUnit,
                  counterText: '',
                ),
              ),
            ),
            IconButton(
              tooltip: l.bazarRemoveItem,
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _items.remove(i);
                i.dispose();
              }),
            ),
          ],
        ),
      ],
    );
  }
}

/// Read-only bazar with share; managers can edit from here.
Future<void> showBazarDetail(BuildContext context, Bazar b) {
  final l = AppLocalizations.of(context);
  return AppSheet.show<void>(
    context,
    title: l.bazarTitle,
    child: _BazarDetail(
      bazar: b,
      onEdit: () {
        Navigator.pop(context);
        showBazarForm(context, existing: b);
      },
    ),
  );
}

/// Bangla (or English) text for WhatsApp/Messenger groups.
String bazarShareText(BuildContext context, Bazar b, {String? buyer}) {
  final l = AppLocalizations.of(context);
  final bn = banglaDigits(context);
  return [
    l.bazarShareHeader(longDate(context, b.date)),
    if (buyer != null) l.bazarShareBuyer(buyer),
    if (b.items.isNotEmpty) '',
    for (final i in b.items)
      '• ${i.name}'
          '${i.qty == null ? '' : ' ${Fmt.digits(_num(i.qty!), bangla: bn)}'}'
          '${i.unit == null ? '' : ' ${i.unit}'}'
          ' — ${money(context, i.price)}',
    if (b.items.isNotEmpty) '',
    l.bazarShareTotal(money(context, b.amount)),
    if (b.note != null) b.note!,
  ].join('\n');
}

class _BazarDetail extends ConsumerWidget {
  const _BazarDetail({required this.bazar, required this.onEdit});

  final Bazar bazar;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final names = {
      for (final m in ref.watch(membersProvider(bazar.messId)).value ?? [])
        m.id: m.displayName,
    };
    final buyer = names[bazar.buyerMemberId];
    final payer = names[bazar.paidByMemberId];
    final bn = banglaDigits(context);
    Widget line(String label, Widget value, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          value,
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        _Label(
          [
            longDate(context, bazar.date),
            ?buyer,
            bazar.paidByMemberId == null
                ? l.moneyPaidFund
                : '${l.moneyPaidPocket}${payer == null ? '' : ' ($payer)'}',
          ].join(' · '),
        ),
        for (final i in bazar.items)
          line(
            [
              i.name,
              if (i.qty != null) Fmt.digits(_num(i.qty!), bangla: bn),
              ?i.unit,
            ].join(' '),
            Money(i.price, banglaDigits: bn),
          ),
        const Divider(),
        line(
          l.moneyFoodTotal,
          Money(bazar.amount, banglaDigits: bn, style: text.titleMedium),
          style: text.titleSmall,
        ),
        if (bazar.note != null) Text(bazar.note!),
        const SizedBox(height: AppSpace.sm),
        Row(
          spacing: AppSpace.sm,
          children: [
            Expanded(
              child: AppButton(
                label: l.bazarShare,
                icon: Icons.share_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: bazarShareText(context, bazar, buyer: buyer),
                  ),
                ),
              ),
            ),
            if (ref.watch(amIManagerProvider))
              Expanded(
                child: AppButton(label: l.edit, onPressed: onEdit),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Expense ───────────────────────────────────────────────────────────────

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({this.existing});

  final Expense? existing;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm>
    with _Submit<_ExpenseForm> {
  late final Expense? _e = widget.existing;
  late final _amount = TextEditingController(
    text: _e == null ? '' : _num(_e.amount),
  );
  late final _note = TextEditingController(text: _e?.note);
  late var _date = _e?.date ?? today();
  late var _category = _e?.categoryId;
  late var _split = _e?.split ?? SplitMethod.equal;
  late var _pocket = _e?.paidByMemberId != null;
  late var _paidBy = _e?.paidByMemberId;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(moneyControllerProvider);
    return _WithMess(
      builder: (messId) {
        final cats =
            ref.watch(expenseCategoriesProvider(messId)).value ?? const [];
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.lg,
            children: [
              _AmountField(controller: _amount, autofocus: _e == null),
              _DateChip(
                value: _date,
                onChanged: (d) => setState(() => _date = d),
              ),
              _Label(l.expenseCategory),
              _Required(
                ok: () => _category != null,
                message: l.expensePickCategory,
                child: Wrap(
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
                        }),
                      ),
                  ],
                ),
              ),
              _Label(l.expenseSplit),
              SegmentedButton<SplitMethod>(
                showSelectedIcon: false,
                segments: [
                  for (final s in SplitMethod.values)
                    ButtonSegment(value: s, label: Text(splitLabel(l, s))),
                ],
                selected: {_split},
                onSelectionChanged: (s) => setState(() => _split = s.first),
              ),
              _Label(
                _split == SplitMethod.meal
                    ? l.expenseSplitMealHelp
                    : l.expenseSplitEqualHelp,
              ),
              _PaidFrom(
                messId: messId,
                pocket: _pocket,
                paidBy: _paidBy,
                onPocket: (v) => setState(() => _pocket = v),
                onPaidBy: (id) => setState(() => _paidBy = id),
              ),
              TextFormField(
                controller: _note,
                maxLength: 300,
                decoration: InputDecoration(labelText: l.moneyNote),
              ),
              footer(
                () => save(
                  () => ctrl.saveExpense(
                    Expense(
                      id: _e?.id ?? uuidV4(),
                      messId: messId,
                      date: _date,
                      categoryId: _category!,
                      amount: parseAmount(_amount.text)!,
                      split: _split,
                      paidByMemberId: _pocket ? _paidBy : null,
                      note: _trimmed(_note),
                    ),
                  ),
                ),
                onDelete: _e == null
                    ? null
                    : () => delete(() => ctrl.deleteExpense(_e)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Deposit ───────────────────────────────────────────────────────────────

class _DepositForm extends ConsumerStatefulWidget {
  const _DepositForm({this.existing});

  final Deposit? existing;

  @override
  ConsumerState<_DepositForm> createState() => _DepositFormState();
}

class _DepositFormState extends ConsumerState<_DepositForm>
    with _Submit<_DepositForm> {
  late final Deposit? _d = widget.existing;
  late final _amount = TextEditingController(
    text: _d == null ? '' : _num(_d.amount),
  );
  late final _trx = TextEditingController(text: _d?.trxId);
  late final _note = TextEditingController(text: _d?.note);
  late var _date = _d?.date ?? today();
  late var _member = _d?.memberId;
  late var _method = _d?.method ?? PayMethod.cash;

  @override
  void dispose() {
    _amount.dispose();
    _trx.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(moneyControllerProvider);
    return _WithMess(
      builder: (messId) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.lg,
          children: [
            _AmountField(
              controller: _amount,
              autofocus: _d == null,
              positive: true,
            ),
            _DateChip(
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            _Label(l.depositMember),
            _Required(
              ok: () => _member != null,
              message: l.moneyPickMember,
              child: _MemberChips(
                messId: messId,
                selected: _member,
                onSelected: (id) => setState(() => _member = id),
              ),
            ),
            _Label(l.depositMethod),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final m in PayMethod.values)
                  ChoiceChip(
                    label: Text(methodLabel(l, m)),
                    selected: m == _method,
                    onSelected: (_) => setState(() => _method = m),
                  ),
              ],
            ),
            if (_method.hasTrxId)
              TextFormField(
                controller: _trx,
                maxLength: 40,
                decoration: InputDecoration(labelText: l.depositTrxId),
              ),
            TextFormField(
              controller: _note,
              maxLength: 300,
              decoration: InputDecoration(labelText: l.moneyNote),
            ),
            footer(
              () => save(
                () => ctrl.saveDeposit(
                  Deposit(
                    id: _d?.id ?? uuidV4(),
                    messId: messId,
                    memberId: _member!,
                    date: _date,
                    amount: parseAmount(_amount.text)!,
                    method: _method,
                    trxId: _method.hasTrxId ? _trimmed(_trx) : null,
                    status: _d?.status ?? DepositStatus.verified,
                    note: _trimmed(_note),
                  ),
                ),
              ),
              onDelete: _d == null
                  ? null
                  : () => delete(() => ctrl.deleteDeposit(_d)),
            ),
          ],
        ),
      ),
    );
  }
}
