import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/ids.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/storage.dart';
import '../../../core/widgets/widgets.dart';
import '../../ai/presentation/ai_entry.dart';
import '../../meals/presentation/meal_widgets.dart' show pickOne;
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../mess/presentation/common.dart';
import '../application/money_providers.dart';
import '../domain/bazar_catalogue.dart';
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

/// A member records their own deposit; it stays pending until verified.
Future<void> showMyDepositSheet(BuildContext context) => _showForm(
  context,
  AppLocalizations.of(context).depositVerifyMine,
  const _MyDepositForm(),
);

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

/// The admin's label from [config] when set, else the built-in one.
String methodLabel(AppLocalizations l, PayMethod m, [PlatformConfig? config]) =>
    config?.methodLabel(m.name, l.localeName) ??
    switch (m) {
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
    this.onChanged,
  });

  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  /// Deposits must be > 0; bazar and expenses may be 0.
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextFormField(
      key: const Key('amount'),
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
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

// ── Receipt photos ────────────────────────────────────────────────────────

/// Camera / gallery → compressed JPEG bytes, or null. Overridden in tests.
final receiptPickerProvider =
    Provider<Future<Uint8List?> Function(BuildContext)>((ref) => _pickPhoto);

Future<Uint8List?> _pickPhoto(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final source = await pickOne<ImageSource>(
    context,
    title: l.receiptAttach,
    options: [
      (ImageSource.camera, l.aiCamera),
      (ImageSource.gallery, l.aiGallery),
    ],
  );
  if (source == null) return null;
  try {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 70,
    );
    return await file?.readAsBytes();
  } catch (e) {
    // Permission denied, no camera, …
    if (context.mounted) showFailure(context, e);
    return null;
  }
}

/// A form's optional photo: picked bytes until saved, then the storage path.
mixin _Photo<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  Uint8List? photo;
  String? photoPath;

  /// Uploads a newly picked photo once, so a retry after a failed save does
  /// not upload again. Throws `AppFailure`; the caller keeps the sheet open.
  Future<String?> uploadPhoto(String messId) async {
    final bytes = photo;
    if (bytes != null) {
      photoPath = await ref
          .read(storageServiceProvider)
          .uploadReceipt(messId, bytes);
      photo = null;
    }
    return photoPath;
  }

  Widget photoField(String label) {
    final l = AppLocalizations.of(context);
    final bytes = photo;
    final path = photoPath;
    if (bytes == null && path == null) {
      if (!ref.featureOn('receipts')) return const SizedBox.shrink();
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(label),
          onPressed: () async {
            final picked = await ref.read(receiptPickerProvider)(context);
            if (picked != null && mounted) setState(() => photo = picked);
          },
        ),
      );
    }
    return Row(
      spacing: AppSpace.md,
      children: [
        bytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.memory(
                  bytes,
                  width: _thumb,
                  height: _thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.square(
                    dimension: _thumb,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              )
            : ReceiptThumb(path: path!),
        Expanded(child: _Label(label)),
        IconButton(
          tooltip: l.receiptRemove,
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            // ponytail: the old object stays in storage; sweep orphans if it matters.
            photo = null;
            photoPath = null;
          }),
        ),
      ],
    );
  }
}

const double _thumb = 72;

/// Signed-URL thumbnail of a stored receipt; tap for the full image.
class ReceiptThumb extends ConsumerWidget {
  const ReceiptThumb({super.key, required this.path, this.size = _thumb});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final box = ref
        .watch(receiptUrlProvider(path))
        .when(
          loading: () => const Center(
            child: SizedBox.square(
              dimension: AppSize.spinner,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => IconButton(
            tooltip: l.retry,
            icon: const Icon(Icons.broken_image_outlined),
            onPressed: () => ref.invalidate(receiptUrlProvider(path)),
          ),
          data: (url) => Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
          ),
        );
    return Semantics(
      button: true,
      label: l.receiptView,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => showReceipt(context, path),
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: context.palette.border),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: box,
        ),
      ),
    );
  }
}

/// Full-screen, zoomable view of a stored receipt.
Future<void> showReceipt(BuildContext context, String path) => showDialog<void>(
  context: context,
  builder: (context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).receiptView)),
      body: Consumer(
        builder: (context, ref, _) => ref
            .watch(receiptUrlProvider(path))
            .when(
              loading: () => const LoadingView(rows: 0),
              error: (e, _) => ErrorView(
                message: failureText(context, e),
                onRetry: () => ref.invalidate(receiptUrlProvider(path)),
              ),
              data: (url) => InteractiveViewer(
                maxScale: 5,
                child: Center(child: Image.network(url)),
              ),
            ),
      ),
    ),
  ),
);

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
    with _Submit<_BazarForm>, _Photo<_BazarForm> {
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

  /// The user typed an amount: item changes stop overwriting it.
  late var _amountTyped = _b != null;

  @override
  void initState() {
    super.initState();
    photoPath = _b?.receiptPath;
  }

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
      _amountTyped = draft.total != null;
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

  /// Items changed: the amount follows their sum until the user types one.
  void _itemsChanged() => setState(() {
    if (_amountTyped) return;
    final sum = _itemsSum;
    _amount.text = sum == 0 ? '' : _num(sum);
  });

  _ItemCtrls? _line(String name) =>
      _items.where((i) => i.name.text.trim() == name).firstOrNull;

  /// Picker chip: adds a line (1 × the default unit), or removes it.
  void _toggle(String name) {
    final line = _line(name);
    if (line != null) {
      _items.remove(line);
      line.dispose();
    } else {
      _items.add(
        _ItemCtrls(
          BazarItem(
            id: '',
            name: name,
            price: 0,
            qty: 1,
            unit: catalogueUnit(
              name,
              ref.read(platformConfigProvider).catalogue,
            ),
          ),
        )..price.clear(),
      );
    }
    _itemsChanged();
  }

  Bazar _build(String messId, String? receiptPath) => Bazar(
    id: _b?.id ?? uuidV4(),
    messId: messId,
    date: _date,
    amount: parseAmount(_amount.text)!,
    buyerMemberId: _buyer,
    paidByMemberId: _pocket ? _paidBy : null,
    note: _trimmed(_note),
    source: _source,
    receiptPath: receiptPath,
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
            if (_b == null &&
                ref.watch(platformConfigProvider.select((c) => c.aiBazarScan)))
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(
                  label: l.bazarScan,
                  icon: Icons.document_scanner_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: saving ? null : _scan,
                ),
              ),
            _AmountField(
              controller: _amount,
              onChanged: (_) => setState(() => _amountTyped = true),
            ),
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
            if (ref.featureOn('bazar_picker'))
              _Picker(
                messId: messId,
                selected: {for (final i in _items) i.name.text.trim()},
                onToggle: _toggle,
              ),
            for (final i in _items) _itemRow(i),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l.bazarPickerCustom),
                onPressed: () => setState(() => _items.add(_ItemCtrls())),
              ),
            ),
            if (_items.any((i) => !i.isEmpty) &&
                parseAmount(_amount.text) != _itemsSum)
              Row(
                children: [
                  Expanded(
                    child: _Label(l.bazarItemsSum(money(context, _itemsSum))),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _amountTyped = false;
                      _amount.text = _num(_itemsSum);
                    }),
                    child: Text(l.bazarUseSum),
                  ),
                ],
              ),
            photoField(l.receiptAttach),
            TextFormField(
              controller: _note,
              maxLength: 300,
              decoration: InputDecoration(labelText: l.moneyNote),
            ),
            footer(
              () => save(
                () async =>
                    ctrl.saveBazar(_build(messId, await uploadPhoto(messId))),
              ),
              onDelete: _b == null
                  ? null
                  : () => delete(() => ctrl.deleteBazar(_b)),
            ),
          ],
        ),
      ),
    );
  }

  /// Name and price, then a qty stepper and the unit.
  Widget _itemRow(_ItemCtrls i) {
    final l = AppLocalizations.of(context);
    final bn = banglaDigits(context);
    String? need(String? v) =>
        !i.isEmpty && (v ?? '').trim().isEmpty ? l.bazarItemInvalid : null;
    final qty = parseAmount(i.qty.text);
    void setQty(double v) => setState(() => i.qty.text = _num(v));
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
                onChanged: (_) => setState(() {}),
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
                onChanged: (_) => _itemsChanged(),
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
          spacing: AppSpace.xs,
          children: [
            IconButton(
              tooltip: '${l.mealCellDecrease} ${l.bazarItemQty}',
              onPressed: qty == null || qty <= 0.5
                  ? null
                  : () => setQty(qty - (qty > 1 ? 1 : 0.5)),
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: AppSize.touch,
              child: Text(
                qty == null ? '—' : Fmt.digits(_num(qty), bangla: bn),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            IconButton(
              tooltip: '${l.mealCellIncrease} ${l.bazarItemQty}',
              onPressed: () =>
                  setQty(qty == null ? 1 : (qty < 1 ? qty + 0.5 : qty + 1)),
              icon: const Icon(Icons.add),
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
              onPressed: () {
                _items.remove(i);
                i.dispose();
                _itemsChanged();
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Categorized item chips: this mess's most bought, then the catalogue.
/// A chip is selected while its line is in the form.
class _Picker extends ConsumerWidget {
  const _Picker({
    required this.messId,
    required this.selected,
    required this.onToggle,
  });

  final String messId;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final frequent = ref.watch(frequentItemsProvider(messId)).value ?? [];
    final groups = <(String, List<String>)>[
      if (frequent.isNotEmpty) (l.bazarPickerFrequent, frequent),
      if (ref.watch(platformConfigProvider).catalogue case final custom?)
        for (final g in custom) (g.name, [for (final i in g.items) i.name])
      else
        for (final MapEntry(:key, :value) in bazarCatalogue.entries)
          (
            switch (key) {
              BazarGroup.staples => l.bazarPickerStaples,
              BazarGroup.veg => l.bazarPickerVeg,
              BazarGroup.protein => l.bazarPickerProtein,
              BazarGroup.spice => l.bazarPickerSpice,
            },
            [for (final i in value) i.name],
          ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        Text(l.bazarPickerHelp, style: Theme.of(context).textTheme.bodySmall),
        for (final (title, names) in groups) ...[
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final n in names)
                FilterChip(
                  label: Text(n),
                  selected: selected.contains(n),
                  onSelected: (_) => onToggle(n),
                ),
            ],
          ),
        ],
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
        if (bazar.receiptPath != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ReceiptThumb(path: bazar.receiptPath!, size: 96),
          ),
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

/// The sheet's split choice: `selected` saves `split = equal` plus shares.
enum _Split { equal, meal, selected }

/// Member checklist with a ভাগ (weight) stepper each, then a display-only
/// preview of every selected member's part of the amount.
class _ShareList extends ConsumerWidget {
  const _ShareList({
    required this.messId,
    required this.amount,
    required this.weights,
    required this.onChanged,
  });

  static const maxWeight = 20.0;

  final String messId;
  final TextEditingController amount;
  final Map<String, double> weights;
  final ValueChanged<Map<String, double>> onChanged;

  /// [w] null = unchecked.
  void _set(String id, double? w) {
    final next = {...weights};
    w == null ? next.remove(id) : next[id] = w;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bn = banglaDigits(context);
    final members = [
      for (final m
          in ref.watch(membersProvider(messId)).value ?? const <Member>[])
        if (weights.containsKey(m.id) ||
            m.status == MemberStatus.active ||
            m.status == MemberStatus.inactive)
          m,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in members)
          Row(
            children: [
              Expanded(
                child: MergeSemantics(
                  child: InkWell(
                    onTap: () =>
                        _set(m.id, weights.containsKey(m.id) ? null : 1),
                    child: Row(
                      children: [
                        Checkbox(
                          value: weights.containsKey(m.id),
                          onChanged: (v) => _set(m.id, v! ? 1 : null),
                        ),
                        Flexible(child: Text(m.displayName)),
                      ],
                    ),
                  ),
                ),
              ),
              if (weights[m.id] case final w?) ...[
                IconButton(
                  tooltip: '${l.splitWeightLess} ${m.displayName}',
                  onPressed: w > 1 ? () => _set(m.id, w - 1) : null,
                  icon: const Icon(Icons.remove),
                ),
                Text(l.splitWeight(Fmt.digits(_num(w), bangla: bn))),
                IconButton(
                  tooltip: '${l.splitWeightMore} ${m.displayName}',
                  onPressed: w < maxWeight ? () => _set(m.id, w + 1) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ],
          ),
        ValueListenableBuilder(
          valueListenable: amount,
          builder: (context, v, _) {
            final a = parseAmount(v.text);
            if (a == null || weights.isEmpty) return const SizedBox.shrink();
            final preview = sharePreview(a, weights);
            return Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Column(
                key: const Key('share-preview'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.xs,
                children: [
                  _Label(l.splitPreview),
                  for (final m in members)
                    if (preview[m.id] case final p?)
                      Row(
                        children: [
                          Expanded(child: Text(m.displayName)),
                          Money(p, banglaDigits: bn),
                        ],
                      ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({this.existing});

  final Expense? existing;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm>
    with _Submit<_ExpenseForm>, _Photo<_ExpenseForm> {
  late final Expense? _e = widget.existing;
  late final _amount = TextEditingController(
    text: _e == null ? '' : _num(_e.amount),
  );
  late final _note = TextEditingController(text: _e?.note);
  late var _date = _e?.date ?? today();
  late var _category = _e?.categoryId;
  late var _split = _e == null
      ? _Split.equal
      : _e.shares.isNotEmpty
      ? _Split.selected
      : _e.split == SplitMethod.meal
      ? _Split.meal
      : _Split.equal;
  late var _weights = {...?_e?.shares};
  late var _pocket = _e?.paidByMemberId != null;
  late var _paidBy = _e?.paidByMemberId;

  @override
  void initState() {
    super.initState();
    photoPath = _e?.receiptPath;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// "Selected members" starts with everyone present on the date, ভাগ 1.
  Future<void> _pickSplit(_Split s, String messId) async {
    setState(() => _split = s);
    if (s != _Split.selected || _weights.isNotEmpty) return;
    final all = await ref.read(membersProvider(messId).future);
    if (!mounted || _split != _Split.selected || _weights.isNotEmpty) return;
    setState(
      () => _weights = {
        for (final m in all)
          if (m.presentOn(_date)) m.id: 1,
      },
    );
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
                          _split = c.defaultSplit == SplitMethod.meal
                              ? _Split.meal
                              : _Split.equal;
                        }),
                      ),
                  ],
                ),
              ),
              _Label(l.expenseSplit),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final (s, label) in [
                    (_Split.equal, l.splitEqualAll),
                    (_Split.meal, l.splitByMeal),
                    // Kept while editing a split that already uses it.
                    if (ref.featureOn('split') || _split == _Split.selected)
                      (_Split.selected, l.splitSelected),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: s == _split,
                      onSelected: (_) => _pickSplit(s, messId),
                    ),
                ],
              ),
              _Label(switch (_split) {
                _Split.equal => l.expenseSplitEqualHelp,
                _Split.meal => l.expenseSplitMealHelp,
                _Split.selected => l.splitSelectedHelp,
              }),
              if (_split == _Split.selected)
                _Required(
                  ok: () => _weights.isNotEmpty,
                  message: l.splitPickMember,
                  child: _ShareList(
                    messId: messId,
                    amount: _amount,
                    weights: _weights,
                    onChanged: (w) => setState(() => _weights = w),
                  ),
                ),
              _PaidFrom(
                messId: messId,
                pocket: _pocket,
                paidBy: _paidBy,
                onPocket: (v) => setState(() => _pocket = v),
                onPaidBy: (id) => setState(() => _paidBy = id),
              ),
              photoField(l.receiptAttach),
              TextFormField(
                controller: _note,
                maxLength: 300,
                decoration: InputDecoration(labelText: l.moneyNote),
              ),
              footer(
                () => save(
                  () async => ctrl.saveExpense(
                    Expense(
                      id: _e?.id ?? uuidV4(),
                      messId: messId,
                      date: _date,
                      categoryId: _category!,
                      amount: parseAmount(_amount.text)!,
                      split: _split == _Split.meal
                          ? SplitMethod.meal
                          : SplitMethod.equal,
                      shares: _split == _Split.selected ? _weights : const {},
                      paidByMemberId: _pocket ? _paidBy : null,
                      note: _trimmed(_note),
                      receiptPath: await uploadPhoto(messId),
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
    with _Submit<_DepositForm>, _Photo<_DepositForm> {
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
  void initState() {
    super.initState();
    photoPath = _d?.screenshotPath;
  }

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
            ..._methodFields(
              l,
              ref.watch(platformConfigProvider),
              _method,
              _trx,
              (m) => setState(() => _method = m),
            ),
            photoField(l.receiptScreenshot),
            TextFormField(
              controller: _note,
              maxLength: 300,
              decoration: InputDecoration(labelText: l.moneyNote),
            ),
            footer(
              () => save(
                () async => ctrl.saveDeposit(
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
                    screenshotPath: await uploadPhoto(messId),
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

/// Method chips, then TrxID for mobile/bank payments.
List<Widget> _methodFields(
  AppLocalizations l,
  PlatformConfig config,
  PayMethod method,
  TextEditingController trx,
  ValueChanged<PayMethod> onMethod,
) => [
  _Label(l.depositMethod),
  Wrap(
    spacing: AppSpace.sm,
    runSpacing: AppSpace.sm,
    children: [
      for (final m in PayMethod.values)
        // A disabled method stays visible only when already picked.
        if (config.methodEnabled(m.name) || m == method)
          ChoiceChip(
            label: Text(methodLabel(l, m, config)),
            selected: m == method,
            onSelected: (_) => onMethod(m),
          ),
    ],
  ),
  if (method.hasTrxId)
    TextFormField(
      controller: trx,
      maxLength: 40,
      decoration: InputDecoration(labelText: l.depositTrxId),
    ),
];

// ── My deposit (member, pending until verified) ───────────────────────────

class _MyDepositForm extends ConsumerStatefulWidget {
  const _MyDepositForm();

  @override
  ConsumerState<_MyDepositForm> createState() => _MyDepositFormState();
}

class _MyDepositFormState extends ConsumerState<_MyDepositForm>
    with _Submit<_MyDepositForm>, _Photo<_MyDepositForm> {
  /// Fixed for the sheet's life, so a retry after a failure is idempotent.
  final _id = uuidV4();
  final _amount = TextEditingController();
  final _trx = TextEditingController();
  var _date = today();
  var _method = PayMethod.bkash;

  @override
  void dispose() {
    _amount.dispose();
    _trx.dispose();
    super.dispose();
  }

  Future<void> _send(String messId) async {
    if (!formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(moneyControllerProvider);
    await run(() async {
      final path = await uploadPhoto(messId);
      await ctrl.recordMyDeposit(
        Deposit(
          id: _id,
          messId: messId,
          // The server uses the caller's own member row.
          memberId: '',
          date: _date,
          amount: parseAmount(_amount.text)!,
          method: _method,
          trxId: _method.hasTrxId ? _trimmed(_trx) : null,
          status: DepositStatus.pending,
          screenshotPath: path,
        ),
      );
    }, l.depositVerifySent);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _WithMess(
      builder: (messId) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.lg,
          children: [
            _Label(l.depositVerifyHelp),
            _AmountField(controller: _amount, autofocus: true, positive: true),
            _DateChip(
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            ..._methodFields(
              l,
              ref.watch(platformConfigProvider),
              _method,
              _trx,
              (m) => setState(() => _method = m),
            ),
            photoField(l.receiptScreenshot),
            footer(() => _send(messId)),
          ],
        ),
      ),
    );
  }
}
