import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show ValueListenable, listEquals, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
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
import '../../messages/domain/message_draft.dart';
import '../../messages/presentation/messages_screens.dart'
    show ReportProblemButton;
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

Future<void> showExpenseForm(BuildContext context, {Expense? existing}) {
  final l = AppLocalizations.of(context);
  return _showForm(
    context,
    existing == null ? l.expenseAdd : l.expenseEdit,
    (key) => _ExpenseForm(key: key, existing: existing),
  );
}

Future<void> showDepositForm(BuildContext context, {Deposit? existing}) {
  final l = AppLocalizations.of(context);
  return _showForm(
    context,
    existing == null ? l.depositAdd : l.depositEdit,
    (key) => _DepositForm(key: key, existing: existing),
  );
}

/// A member records their own deposit; it stays pending until verified.
Future<void> showMyDepositSheet(BuildContext context) => _showForm(
  context,
  AppLocalizations.of(context).depositVerifyMine,
  (key) => _MyDepositForm(key: key),
);

/// The form pops with the snackbar text (saved / deleted). Its save row
/// (and the bazar's running total) sits in the sheet's sticky footer.
Future<void> _showForm(
  BuildContext context,
  String title,
  Widget Function(GlobalKey<_Submit> key) form,
) async {
  final key = GlobalKey<_Submit>();
  final done = await AppSheet.show<String>(
    context,
    title: title,
    child: form(key),
    actions: [_StickyFooter(form: key)],
  );
  if (done != null && context.mounted) showSnack(context, done);
}

/// Rebuilds with the form (every setState ticks [_Submit.footerTick]).
class _StickyFooter extends ConsumerStatefulWidget {
  const _StickyFooter({required this.form});

  final GlobalKey<_Submit> form;

  @override
  ConsumerState<_StickyFooter> createState() => _StickyFooterState();
}

class _StickyFooterState extends ConsumerState<_StickyFooter> {
  @override
  Widget build(BuildContext context) {
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null) return const SizedBox.shrink();
    final s = widget.form.currentState;
    if (s == null) {
      // The form mounts first in the same frame; this only guards odd trees.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: s.footerTick,
      builder: (context, _) => s.footer(context, messId),
    );
  }
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

  /// Ticks on every setState so the sticky footer follows the form.
  final footerTick = ValueNotifier(0);

  /// The footer's save, for the current mess.
  void onSave(String messId);

  /// Delete, only when editing.
  VoidCallback? get onDelete => null;

  /// Shown above the buttons (the bazar's running total).
  Widget? footerLead(BuildContext context) => null;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    footerTick.value++;
  }

  @override
  void dispose() {
    footerTick.dispose();
    super.dispose();
  }

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

  /// Error line, the optional lead, then the action row.
  Widget footer(BuildContext context, String messId) {
    final l = AppLocalizations.of(context);
    final onDelete = this.onDelete;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.md,
      children: [
        if (error != null)
          Text(
            failureText(context, error!),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.palette.due),
          ),
        ?footerLead(context),
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
                onPressed: () => onSave(messId),
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

class _AmountField extends StatefulWidget {
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
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  final _focus = FocusNode();
  Animation<double>? _entrance;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusAfterEntrance(),
      );
    }
  }

  /// Opening the keyboard while the sheet still slides in makes both
  /// animations stutter, so focus once the route has arrived.
  void _focusAfterEntrance() {
    if (!mounted) return;
    final a = ModalRoute.of(context)?.animation;
    if (a == null || a.isCompleted) {
      _focus.requestFocus();
    } else {
      _entrance = a..addStatusListener(_onStatus);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status.isCompleted && mounted) _focus.requestFocus();
    if (status.isCompleted || status.isDismissed) {
      _entrance?.removeStatusListener(_onStatus);
      _entrance = null;
    }
  }

  @override
  void dispose() {
    _entrance?.removeStatusListener(_onStatus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextFormField(
      key: const Key('amount'),
      controller: widget.controller,
      focusNode: _focus,
      onChanged: widget.onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9০-৯.]'))],
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(labelText: l.moneyAmount, prefixText: '৳ '),
      validator: (v) {
        final a = parseAmount(v ?? '');
        if (a == null) return l.moneyAmountInvalid;
        if (widget.positive && a == 0) return l.depositAmountPositive;
        return null;
      },
    );
  }
}

/// The entry's date. Closed months cannot be picked ([firstOpenDateProvider]).
class _DateChip extends ConsumerWidget {
  const _DateChip({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messId = ref.watch(currentMessIdProvider);
    final open = messId == null
        ? null
        : ref.watch(firstOpenDateProvider(messId)).value;
    final first = open ?? DateTime(2020);
    var last = today().add(const Duration(days: 31));
    if (last.isBefore(first)) last = first;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ActionChip(
        avatar: const Icon(Icons.calendar_today_outlined),
        label: Text(longDate(context, value)),
        tooltip: AppLocalizations.of(context).moneyChangeDate,
        onPressed: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value.isBefore(first)
                ? first
                : value.isAfter(last)
                ? last
                : value,
            firstDate: first,
            lastDate: last,
          );
          if (d != null) onChanged(dayOnly(d));
        },
      ),
    );
  }
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
        InkSegmented<bool>(
          segments: [(false, l.moneyPaidFund), (true, l.moneyPaidPocket)],
          selected: pocket,
          onChanged: onPocket,
        ),
        AnimatedSize(
          duration: AppMotion.of(context, AppMotion.base),
          curve: AppMotion.state,
          alignment: Alignment.topCenter,
          child: !pocket
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpace.sm,
                  children: [
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
                ),
        ),
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
//
// Performance: typing never rebuilds the page. Rows own their rebuilds (each
// field listens to its own controller), the total is a listenable only the
// footer and the sum hint watch, the item list and the picker are cached
// widget instances that rebuild only on add/remove, and each picker chip
// rebuilds only when its own check flips.

/// One item row's state. It lives outside the row widget, so a lazily
/// rebuilt row (scrolled away and back) keeps its text, qty and unit.
class _Line {
  _Line({
    String name = '',
    double? price,
    this.qty = 1,
    this.unit,
    this.fresh = true,
  }) : name = TextEditingController(text: name),
       price = TextEditingController(text: price == null ? '' : _num(price));

  final TextEditingController name, price;
  double? qty;
  String? unit;

  /// Added after the page opened: the row grows in once.
  bool fresh;

  bool get isEmpty => name.text.trim().isEmpty && price.text.trim().isEmpty;

  /// Empty lines are skipped on save; others need a name and a valid price.
  bool get valid =>
      isEmpty ||
      (name.text.trim().isNotEmpty && parseAmount(price.text) != null);

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

/// 1410.5 → "1410.5", 250.0 → "250" (for prefilled fields).
String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Add / edit a bazar on a full-screen page: who went, who paid, the total,
/// then the items (one compact row each) with the catalogue picker.
Future<void> showBazarForm(BuildContext context, {Bazar? existing}) async {
  final done = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _BazarPage(existing: existing),
    ),
  );
  if (done != null && context.mounted) showSnack(context, done);
}

class _BazarPage extends ConsumerStatefulWidget {
  const _BazarPage({this.existing});

  final Bazar? existing;

  @override
  ConsumerState<_BazarPage> createState() => _BazarPageState();
}

class _BazarPageState extends ConsumerState<_BazarPage>
    with _Submit<_BazarPage>, _Photo<_BazarPage> {
  late final Bazar? _b = widget.existing;
  late final _amount = TextEditingController(
    text: _b == null ? '' : _num(_b.amount),
  );
  late final _note = TextEditingController(text: _b?.note);
  late var _date = _b?.date ?? today();

  /// In pick order; the first is mirrored into `buyer_member_id`.
  late final _buyers = <String>{...?_b?.buyers};

  /// Null = the mess fund.
  late var _paidBy = _b?.paidByMemberId;
  late var _source = _b?.source ?? 'app';

  /// The user typed an amount: item changes stop overwriting it.
  late var _amountTyped = _b != null;

  /// The rows, changed only by add / remove / undo / scan.
  final _lines = ValueNotifier<List<_Line>>(const []);

  /// Every line ever made, disposed with the page. A removed row is never
  /// disposed on the spot: its fields still build in the frame that drops it.
  final _made = <_Line>[];

  /// Sum of the line prices.
  final _sum = ValueNotifier<double>(0);

  /// The lines' names, for the picker's checks. Notifies only on a change.
  final _names = ValueNotifier<Set<String>>(const {});

  /// Save-blocking problems, repeated in the footer: the field showing the
  /// error may be scrolled away (or an unbuilt row of the lazy list).
  var _problems = const <String>[];

  @override
  void initState() {
    super.initState();
    photoPath = _b?.receiptPath;
    _setLines([
      for (final i in _b?.items ?? const <BazarItem>[])
        _track(
          _Line(
            name: i.name,
            price: i.price,
            qty: i.qty,
            unit: i.unit,
            fresh: false,
          ),
        ),
    ]);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _lines.dispose();
    _sum.dispose();
    _names.dispose();
    for (final i in _made) {
      i.dispose();
    }
    super.dispose();
  }

  _Line _track(_Line line) {
    _made.add(line);
    line.price.addListener(_recalc);
    line.name.addListener(_rename);
    return line;
  }

  void _setLines(List<_Line> next) {
    _lines.value = next;
    _recalc();
    _rename();
  }

  /// The amount follows the items' sum until the user types one.
  /// A filled-in amount in the locale's digits, like the user would type it.
  String _typed(double v) => Fmt.digits(_num(v), bangla: banglaDigits(context));

  void _recalc() {
    final sum = itemsTotal([
      for (final i in _lines.value) parseAmount(i.price.text) ?? 0,
    ]);
    _sum.value = sum;
    if (_amountTyped) return;
    final text = sum == 0 ? '' : _typed(sum);
    if (_amount.text != text) _amount.text = text;
  }

  void _rename() {
    final names = {for (final i in _lines.value) i.name.text.trim()}
      ..remove('');
    if (!setEquals(names, _names.value)) _names.value = names;
  }

  /// Picker chip: adds a line (1 × the catalogue unit), or removes it.
  void _toggle(String name) {
    final lines = _lines.value;
    final hit = lines.where((i) => i.name.text.trim() == name).firstOrNull;
    _setLines(
      hit != null
          ? [
              for (final i in lines)
                if (i != hit) i,
            ]
          : [
              ...lines,
              _track(
                _Line(
                  name: name,
                  unit: catalogueUnit(
                    name,
                    ref.read(platformConfigProvider).catalogue,
                  ),
                ),
              ),
            ],
    );
  }

  void _addBlank() => _setLines([..._lines.value, _track(_Line())]);

  /// Swipe-to-delete, with an undo that puts the line back where it was.
  void _remove(_Line line) {
    final lines = [..._lines.value];
    final at = lines.indexOf(line);
    if (at < 0) return;
    _setLines(lines..removeAt(at));
    final l = AppLocalizations.of(context);
    AppSnack.show(
      context,
      l.bazarItemRemoved,
      icon: Icons.delete_outline,
      actionLabel: l.undo,
      onAction: () {
        final now = _lines.value;
        if (!mounted || now.contains(line)) return;
        line.fresh = true;
        _setLines([...now]..insert(math.min(at, now.length), line));
      },
    );
  }

  /// AI reads a receipt or ফর্দ into a draft; the user still reviews and saves.
  Future<void> _scan() async {
    final draft = await scanBazarReceipt(context);
    if (draft == null || !mounted) return;
    _amountTyped = draft.total != null;
    _source = 'ai';
    _setLines([
      for (final d in draft.items)
        _track(_Line(name: d.name, price: d.price, qty: d.qty, unit: d.unit)),
    ]);
    _amount.text = _num(
      draft.total ?? itemsTotal(draft.items.map((d) => d.price)),
    );
  }

  Bazar _build(String messId, String? receiptPath) => Bazar(
    id: _b?.id ?? uuidV4(),
    messId: messId,
    date: _date,
    amount: parseAmount(_amount.text)!,
    buyers: [..._buyers],
    paidByMemberId: _paidBy,
    note: _trimmed(_note),
    source: _source,
    receiptPath: receiptPath,
    items: [
      for (final i in _lines.value)
        if (!i.isEmpty)
          BazarItem(
            id: uuidV4(),
            name: i.name.text.trim(),
            price: parseAmount(i.price.text)!,
            qty: i.qty,
            unit: i.unit,
          ),
    ],
  );

  @override
  void onSave(String messId) {
    final formOk = formKey.currentState!.validate();
    final l = AppLocalizations.of(context);
    final problems = [
      if (_buyers.isEmpty) l.bazarPickBuyer,
      if (!_lines.value.every((i) => i.valid)) l.bazarItemInvalid,
    ];
    if (!listEquals(problems, _problems)) setState(() => _problems = problems);
    if (!formOk || problems.isNotEmpty) return;
    final ctrl = ref.read(moneyControllerProvider);
    run(
      () async => ctrl.saveBazar(_build(messId, await uploadPhoto(messId))),
      l.moneySaved,
    );
  }

  @override
  VoidCallback? get onDelete => switch (_b) {
    null => null,
    final b => () => delete(
      () => ref.read(moneyControllerProvider).deleteBazar(b),
    ),
  };

  /// Built once: rebuilds only when lines are added or removed.
  late final Widget _itemsSliver = ValueListenableBuilder<List<_Line>>(
    valueListenable: _lines,
    builder: (context, lines, _) {
      final p = context.palette;
      return DecoratedSliver(
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppElevation.raised(p),
        ),
        sliver: SliverList.builder(
          itemCount: lines.length + 1,
          findChildIndexCallback: (key) => switch (key) {
            ObjectKey(:final value) when lines.contains(value) => lines.indexOf(
              value as _Line,
            ),
            ValueKey<String>(value: 'add') => lines.length,
            _ => null,
          },
          itemBuilder: (context, i) => i == lines.length
              ? _AddLineRow(
                  key: const ValueKey('add'),
                  divided: lines.isNotEmpty,
                  onTap: _addBlank,
                )
              : _LineRow(
                  key: ObjectKey(lines[i]),
                  line: lines[i],
                  first: i == 0,
                  onRemove: _remove,
                ),
        ),
      );
    },
  );

  /// Built once: the picker keeps its own state (open, tab, search).
  late final Widget _picker = _Picker(
    selected: _names,
    onToggle: _toggle,
    open: _b == null,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final onDelete = this.onDelete;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(_b == null ? l.bazarAdd : l.bazarEdit),
        actions: [
          if (onDelete != null)
            PopupMenuButton<int>(
              enabled: !saving,
              onSelected: (_) => onDelete(),
              itemBuilder: (_) => [
                PopupMenuItem(value: 0, child: Text(l.delete)),
              ],
            ),
        ],
      ),
      body: messId == null
          ? Padding(
              padding: const EdgeInsets.all(AppSpace.gutter),
              child: Text(l.moneyNoMess),
            )
          : Column(
              children: [
                Expanded(
                  child: Form(
                    key: formKey,
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.gutter,
                            AppSpace.xs,
                            AppSpace.gutter,
                            AppSpace.md,
                          ),
                          // Not lazy: its form fields must stay mounted to validate.
                          sliver: SliverToBoxAdapter(child: _top(messId)),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.gutter,
                          ),
                          sliver: _itemsSliver,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(AppSpace.gutter),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: AppSpace.lg,
                              children: [
                                photoField(l.receiptAttach),
                                TextFormField(
                                  controller: _note,
                                  maxLength: 300,
                                  decoration: InputDecoration(
                                    labelText: l.moneyNote,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _footer(context, messId),
              ],
            ),
    );
  }

  /// Date, who went, who paid, the total, the items heading and the picker.
  Widget _top(String messId) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final all = ref.watch(membersProvider(messId)).value ?? const <Member>[];
    final scan =
        _b == null &&
        ref.watch(platformConfigProvider.select((c) => c.aiBazarScan));
    Widget section(String title, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        Text(title, style: text.titleSmall),
        child,
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.sm,
          children: [
            _DateChip(
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            if (scan)
              TextButton.icon(
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(l.bazarScan),
                onPressed: saving ? null : _scan,
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        section(
          l.bazarBuyers,
          _Required(
            ok: () => _buyers.isNotEmpty,
            message: l.bazarPickBuyer,
            child: Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final m in _pickable(all, null))
                  FilterChip(
                    avatar: InitialsAvatar(m.displayName, size: 24),
                    showCheckmark: false,
                    label: Text(m.displayName),
                    selected: _buyers.contains(m.id),
                    onSelected: (on) => setState(
                      () => on ? _buyers.add(m.id) : _buyers.remove(m.id),
                    ),
                  ),
                // A buyer who has since left still shows on an edit.
                for (final m in all)
                  if (_buyers.contains(m.id) &&
                      !_pickable(all, null).contains(m))
                    FilterChip(
                      label: Text(m.displayName),
                      selected: true,
                      onSelected: (_) => setState(() => _buyers.remove(m.id)),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        section(
          l.bazarPayer,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.xs,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: AppSpace.sm,
                  children: [
                    ChoiceChip(
                      avatar: const Icon(Icons.account_balance_wallet_outlined),
                      label: Text(l.moneyPaidFund),
                      selected: _paidBy == null,
                      onSelected: (_) => setState(() => _paidBy = null),
                    ),
                    for (final m in _pickable(all, _paidBy))
                      ChoiceChip(
                        avatar: InitialsAvatar(m.displayName, size: 24),
                        showCheckmark: false,
                        label: Text(m.displayName),
                        selected: _paidBy == m.id,
                        onSelected: (_) => setState(() => _paidBy = m.id),
                      ),
                  ],
                ),
              ),
              if (_paidBy != null) _Label(l.moneyPaidPocketHelp),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        _AmountField(
          controller: _amount,
          onChanged: (_) => _amountTyped = true,
        ),
        ListenableBuilder(
          listenable: Listenable.merge([_amount, _sum]),
          builder: (context, _) {
            final sum = _sum.value;
            if (sum == 0 || parseAmount(_amount.text) == sum) {
              return const SizedBox.shrink();
            }
            return Row(
              children: [
                Expanded(child: _Label(l.bazarItemsSum(money(context, sum)))),
                TextButton(
                  onPressed: () {
                    _amountTyped = false;
                    _amount.text = _typed(sum);
                  },
                  child: Text(l.bazarUseSum),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.xl),
        Text(l.bazarItems, style: text.titleSmall),
        const SizedBox(height: AppSpace.sm),
        if (ref.featureOn('bazar_picker')) ...[
          _picker,
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }

  /// Error line, then "মোট" with the rolling total beside Save. Only this
  /// part listens to the amount.
  Widget _footer(BuildContext context, String messId) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final error = this.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.md,
            AppSpace.gutter,
            AppSpace.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.sm,
            children: [
              for (final e in [
                if (error != null) failureText(context, error),
                ..._problems,
              ])
                Text(e, style: text.bodyMedium?.copyWith(color: p.due)),
              Row(
                spacing: AppSpace.lg,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.bazarTotal, style: AppType.overline(context)),
                        ValueListenableBuilder(
                          valueListenable: _amount,
                          builder: (context, v, _) => FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: RollingNumber.money(
                              parseAmount(v.text) ?? 0,
                              banglaDigits: banglaDigits(context),
                              style: text.titleLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AppButton(
                      label: l.moneySave,
                      loading: saving,
                      onPressed: () => onSave(messId),
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

/// One item on one ~56 dp row: name (edit in place), `− ১ কেজি +` (tap the
/// unit to change it), price. Swipe left to remove. Rebuilds only itself.
class _LineRow extends StatefulWidget {
  const _LineRow({
    super.key,
    required this.line,
    required this.first,
    required this.onRemove,
  });

  final _Line line;
  final bool first;
  final ValueChanged<_Line> onRemove;

  @override
  State<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends State<_LineRow> {
  /// Read once: a row remounted by scrolling does not grow in again.
  late final bool _grow = widget.line.fresh;

  @override
  void initState() {
    super.initState();
    widget.line.fresh = false;
  }

  void _setQty(double v) => setState(() => widget.line.qty = v);

  Future<void> _pickUnit() async {
    final l = AppLocalizations.of(context);
    final line = widget.line;
    final picked = await pickOne<String>(
      context,
      title: l.bazarItemUnit,
      options: [
        for (final u in {?line.unit, ...bazarUnits}) (u, u),
        ('', l.bazarUnitNone),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => line.unit = picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final line = widget.line;
    final qty = line.qty;
    final qtyText = [
      qty == null ? '—' : Fmt.digits(_num(qty), bangla: banglaDigits(context)),
      ?line.unit,
    ].join(' ');
    String? need(String? v) =>
        !line.isEmpty && (v ?? '').trim().isEmpty ? l.bazarItemInvalid : null;
    const none = InputBorder.none;
    OutlineInputBorder box([Color? c]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: c == null ? BorderSide.none : BorderSide(color: c),
    );
    final name = TextFormField(
      key: const Key('item-name'),
      controller: line.name,
      autofocus: _grow && line.name.text.isEmpty,
      maxLength: 60,
      textInputAction: TextInputAction.next,
      style: text.bodyLarge,
      decoration: InputDecoration(
        hintText: l.bazarItemName,
        counterText: '',
        isDense: true,
        border: none,
        enabledBorder: none,
        focusedBorder: none,
        errorBorder: none,
        focusedErrorBorder: none,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      ),
      validator: need,
    );
    final minus = _QtyButton(
      icon: Icons.remove,
      label: '${l.mealCellDecrease} ${l.bazarItemQty}',
      onTap: qty == null || qty <= 0.5
          ? null
          : () => _setQty(qty - (qty > 1 ? 1 : 0.5)),
    );
    final label = Semantics(
      button: true,
      label: l.bazarQtyLabel(qtyText),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: _pickUnit,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSize.stepTarget,
            minHeight: AppSize.touch,
          ),
          child: Center(
            widthFactor: 1,
            child: PopOnChange(
              value: qty,
              child: Text(
                qtyText,
                key: const Key('item-qty'),
                maxLines: 1,
                style: text.labelLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final plus = _QtyButton(
      icon: Icons.add,
      label: '${l.mealCellIncrease} ${l.bazarItemQty}',
      onTap: () => _setQty(qty == null ? 1 : (qty < 1 ? qty + 0.5 : qty + 1)),
    );
    final price = SizedBox(
      width: _priceWidth,
      child: TextFormField(
        key: const Key('item-price'),
        controller: line.price,
        textAlign: TextAlign.start,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[0-9০-৯.]')),
        ],
        style: text.titleSmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          hintText: l.bazarItemPrice,
          prefixText: '৳',
          isDense: true,
          filled: true,
          fillColor: p.surfaceMuted,
          errorMaxLines: 2,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.md,
          ),
          border: box(),
          enabledBorder: box(),
          focusedBorder: box(p.ink),
          errorBorder: box(p.due),
          focusedErrorBorder: box(p.due),
        ),
        validator: (v) =>
            need(v) ??
            (line.isEmpty || parseAmount(v!) != null
                ? null
                : l.moneyAmountInvalid),
      ),
    );
    final row = Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpace.lg,
        end: AppSpace.md,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.gridRow),
        // One line normally; at a narrow width or a large text scale the
        // name gets its own line and the qty label may shrink.
        child: LayoutBuilder(
          builder: (context, box) =>
              box.maxWidth / MediaQuery.textScalerOf(context).scale(1) >=
                  _oneLineWidth
              ? Row(
                  children: [
                    Expanded(child: name),
                    minus,
                    label,
                    plus,
                    const SizedBox(width: AppSpace.xs),
                    price,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    name,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        minus,
                        Flexible(child: label),
                        plus,
                        const SizedBox(width: AppSpace.xs),
                        price,
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
    return Dismissible(
      key: ObjectKey(line),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onRemove(line),
      background: ColoredBox(
        color: p.due,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: Icon(Icons.delete_outline, color: p.onInk),
          ),
        ),
      ),
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(label: l.bazarRemoveItem): () =>
              widget.onRemove(line),
        },
        child: _Appear(
          animate: _grow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hairline(visible: !widget.first),
              row,
            ],
          ),
        ),
      ),
    );
  }
}

const double _priceWidth = 96;

/// Row width (per text-scale unit) below which an item takes two lines.
const double _oneLineWidth = 280;

/// The inset hairline between rows on the items card.
class _Hairline extends StatelessWidget {
  const _Hairline({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: AppSpace.lg),
    child: Divider(
      height: AppSize.hairline,
      color: visible ? null : Colors.transparent,
    ),
  );
}

/// The card's last row: "+ আইটেম যোগ করুন".
class _AddLineRow extends StatelessWidget {
  const _AddLineRow({super.key, required this.divided, required this.onTap});

  final bool divided;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hairline(visible: divided),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: divided
                ? const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.md),
                  )
                : BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.gridRow),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                child: Row(
                  spacing: AppSpace.md,
                  children: [
                    Icon(Icons.add, size: AppSize.spinner, color: p.ink),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).bazarAddItem,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A 28 dp circle in a 40 × 48 dp hit area (the meal grid's step button).
class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.label, this.onTap});

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
      child: PressableScale(
        enabled: on,
        haptic: on,
        scale: 0.85,
        child: InkResponse(
          onTap: onTap,
          radius: AppSize.stepTarget / 2,
          child: SizedBox(
            width: AppSize.stepTarget,
            height: AppSize.touch,
            child: Center(
              child: AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.fast),
                width: AppSize.stepFace,
                height: AppSize.stepFace,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? p.surfaceMuted : Colors.transparent,
                  border: Border.all(color: on ? p.surfaceMuted : p.border),
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
      ),
    );
  }
}

/// "তালিকা থেকে বাছুন": a collapsible card with a search field, scrolling
/// category tabs and the chips of one tab (or the search's matches). A chip
/// is checked while its line is on the bazar; tapping toggles the line.
class _Picker extends ConsumerStatefulWidget {
  const _Picker({
    required this.selected,
    required this.onToggle,
    required this.open,
  });

  final ValueListenable<Set<String>> selected;
  final ValueChanged<String> onToggle;

  /// Starts open (new bazar) or collapsed (edit).
  final bool open;

  @override
  ConsumerState<_Picker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<_Picker> {
  late var _open = widget.open;
  final _query = TextEditingController();
  var _tab = 0;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<(String, List<String>)> _groups(AppLocalizations l) {
    final messId = ref.watch(currentMessIdProvider);
    final frequent = messId == null
        ? const <String>[]
        : ref.watch(frequentItemsProvider(messId)).value ?? const [];
    return [
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
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final groups = _groups(l);
    final tab = groups.isEmpty ? 0 : math.min(_tab, groups.length - 1);
    final q = _query.text.trim();
    final names = q.isEmpty
        ? (groups.isEmpty ? const <String>[] : groups[tab].$2)
        : {
            for (final (_, ns) in groups)
              for (final n in ns)
                if (n.toLowerCase().contains(q.toLowerCase())) n,
          }.toList();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.touch),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.sm,
                ),
                child: Row(
                  spacing: AppSpace.md,
                  children: [
                    Icon(
                      Icons.playlist_add,
                      size: AppSize.spinner,
                      color: p.inkSecondary,
                    ),
                    Expanded(
                      child: Text(l.bazarPickerTitle, style: text.labelLarge),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: AppMotion.of(context, AppMotion.base),
                      curve: AppMotion.state,
                      child: Icon(Icons.expand_more, color: p.inkSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.of(context, AppMotion.base),
            curve: AppMotion.state,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      0,
                      AppSpace.lg,
                      AppSpace.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpace.md,
                      children: [
                        TextField(
                          key: const Key('picker-search'),
                          controller: _query,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: l.bazarPickerSearch,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: q.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).deleteButtonTooltip,
                                    icon: const Icon(Icons.close),
                                    onPressed: () => setState(_query.clear),
                                  ),
                          ),
                        ),
                        if (q.isEmpty && groups.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final (i, (title, _)) in groups.indexed)
                                  _Tab(
                                    title,
                                    selected: i == tab,
                                    onTap: () => setState(() => _tab = i),
                                  ),
                              ],
                            ),
                          ),
                        Wrap(
                          spacing: AppSpace.sm,
                          runSpacing: AppSpace.sm,
                          children: [
                            for (final n in names)
                              _PickChip(
                                key: ValueKey(n),
                                name: n,
                                selected: widget.selected,
                                onToggle: widget.onToggle,
                              ),
                            if (q.isNotEmpty && !names.contains(q))
                              ActionChip(
                                avatar: const Icon(Icons.add),
                                label: Text(l.bazarPickerAddNamed(q)),
                                onPressed: () {
                                  widget.onToggle(q);
                                  setState(_query.clear);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A category tab: label with an ink underline when selected.
class _Tab extends StatelessWidget {
  const _Tab(this.label, {required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.touch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpace.xs,
              children: [
                Text(
                  label,
                  style: text.labelLarge?.copyWith(
                    color: selected ? p.ink : p.inkSecondary,
                  ),
                ),
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.chip),
                  curve: AppMotion.state,
                  height: 2,
                  width: selected ? AppSpace.xl : 0,
                  decoration: BoxDecoration(
                    color: p.ink,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A catalogue chip that rebuilds only when its own check flips.
class _PickChip extends StatefulWidget {
  const _PickChip({
    super.key,
    required this.name,
    required this.selected,
    required this.onToggle,
  });

  final String name;
  final ValueListenable<Set<String>> selected;
  final ValueChanged<String> onToggle;

  @override
  State<_PickChip> createState() => _PickChipState();
}

class _PickChipState extends State<_PickChip> {
  late bool _on = widget.selected.value.contains(widget.name);

  @override
  void initState() {
    super.initState();
    widget.selected.addListener(_sync);
  }

  @override
  void dispose() {
    widget.selected.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    final on = widget.selected.value.contains(widget.name);
    if (on != _on) setState(() => _on = on);
  }

  @override
  Widget build(BuildContext context) => PopOnChange(
    value: _on,
    child: FilterChip(
      label: Text(widget.name),
      selected: _on,
      onSelected: (_) => widget.onToggle(widget.name),
    ),
  );
}

/// Overlapping initials of everyone who went to the bazar (3, then "+n").
class BuyerAvatars extends StatelessWidget {
  const BuyerAvatars(this.names, {super.key, this.size = 24});

  final List<String> names;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    final p = context.palette;
    final shown = names.take(3).toList();
    final more = names.length - shown.length;
    final step = size * 0.7;
    final count = shown.length + (more > 0 ? 1 : 0);
    Widget ring(Widget child) => DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: p.surfaceRaised, width: 1.5),
      ),
      child: child,
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: size + step * (count - 1),
        height: size,
        child: Stack(
          children: [
            for (final (i, n) in shown.indexed)
              PositionedDirectional(
                start: step * i,
                child: ring(InitialsAvatar(n, size: size)),
              ),
            if (more > 0)
              PositionedDirectional(
                start: step * shown.length,
                child: ring(
                  Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.surfaceMuted,
                    ),
                    child: Text(
                      '+${Fmt.digits('$more', bangla: banglaDigits(context))}',
                      textScaler: TextScaler.noScaling,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: p.inkSecondary,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
    final names = <String, String>{
      for (final m
          in ref.watch(membersProvider(bazar.messId)).value ?? const <Member>[])
        m.id: m.displayName,
    };
    final buyerNames = [for (final id in bazar.buyers) ?names[id]];
    final buyer = bazar.buyerNames(names);
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
        if (buyer != null)
          Row(
            spacing: AppSpace.sm,
            children: [
              BuyerAvatars(buyerNames),
              Expanded(child: Text(buyer, style: text.titleSmall)),
            ],
          ),
        _Label(
          [
            longDate(context, bazar.date),
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
        if (!ref.watch(amIManagerProvider) && ref.featureOn('messages'))
          ReportProblemButton(
            popFirst: true,
            draft: MessageDraft(
              refType: 'bazar',
              refId: bazar.id,
              refLabel: entryLabel(
                context,
                l.bazarTitle,
                bazar.amount,
                bazar.date,
              ),
            ),
          ),
      ],
    );
  }
}

/// "বাজার ৳1,250 · ৮ অক্টোবর": what a report is about.
String entryLabel(
  BuildContext context,
  String kind,
  num amount,
  DateTime date,
) => '$kind ${money(context, amount)} · ${shortDate(context, date)}';

/// A member's read-only deposit or expense, with "report a problem".
Future<void> showEntryDetail(
  BuildContext context, {
  required String title,
  required double amount,
  required List<String> facts,
  required MessageDraft draft,
  String? note,
  String? receiptPath,
}) => AppSheet.show<void>(
  context,
  title: title,
  child: Builder(
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        Money(
          amount,
          banglaDigits: banglaDigits(context),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        _Label(facts.join(' · ')),
        if (note != null) Text(note),
        if (receiptPath != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ReceiptThumb(path: receiptPath, size: 96),
          ),
        const SizedBox(height: AppSpace.sm),
        ReportProblemButton(draft: draft, popFirst: true),
      ],
    ),
  ),
);

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
                PopOnChange(
                  value: w,
                  child: Text(l.splitWeight(Fmt.digits(_num(w), bangla: bn))),
                ),
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
                          RollingNumber.money(p, banglaDigits: bn),
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
  const _ExpenseForm({super.key, this.existing});

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
  void onSave(String messId) => save(
    () async => ref
        .read(moneyControllerProvider)
        .saveExpense(
          Expense(
            id: _e?.id ?? uuidV4(),
            messId: messId,
            date: _date,
            categoryId: _category!,
            amount: parseAmount(_amount.text)!,
            split: _split == _Split.meal ? SplitMethod.meal : SplitMethod.equal,
            shares: _split == _Split.selected ? _weights : const {},
            paidByMemberId: _pocket ? _paidBy : null,
            note: _trimmed(_note),
            receiptPath: await uploadPhoto(messId),
          ),
        ),
  );

  @override
  VoidCallback? get onDelete => switch (_e) {
    null => null,
    final e => () => delete(
      () => ref.read(moneyControllerProvider).deleteExpense(e),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
              InkSegmented<_Split>(
                segments: [
                  (_Split.equal, l.splitEqualAll),
                  (_Split.meal, l.splitByMeal),
                  // Kept while editing a split that already uses it.
                  if (ref.featureOn('split') || _split == _Split.selected)
                    (_Split.selected, l.splitSelected),
                ],
                selected: _split,
                onChanged: (s) => _pickSplit(s, messId),
              ),
              // Grows smoothly instead of jumping when the member list opens.
              AnimatedSize(
                duration: AppMotion.of(context, AppMotion.base),
                curve: AppMotion.state,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpace.lg,
                  children: [
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
                  ],
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
            ],
          ),
        );
      },
    );
  }
}

// ── Deposit ───────────────────────────────────────────────────────────────

class _DepositForm extends ConsumerStatefulWidget {
  const _DepositForm({super.key, this.existing});

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
  void onSave(String messId) => save(
    () async => ref
        .read(moneyControllerProvider)
        .saveDeposit(
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
  );

  @override
  VoidCallback? get onDelete => switch (_d) {
    null => null,
    final d => () => delete(
      () => ref.read(moneyControllerProvider).deleteDeposit(d),
    ),
  };

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
            avatar: Icon(switch (m) {
              PayMethod.cash => Icons.payments_outlined,
              PayMethod.bkash || PayMethod.nagad => Icons.phone_android,
              PayMethod.bank => Icons.account_balance_outlined,
              PayMethod.other => Icons.more_horiz,
            }),
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
  const _MyDepositForm({super.key});

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

  @override
  void onSave(String messId) => _send(messId);

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
          ],
        ),
      ),
    );
  }
}

/// A new bazar line grows open and fades in (instant with reduced motion).
class _Appear extends StatefulWidget {
  const _Appear({required this.child, this.animate = true});

  final Widget child;

  /// False: shown as-is (e.g. a row remounted by scrolling).
  final bool animate;

  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: AppMotion.base);
  late final _t = _c.drive(CurveTween(curve: AppMotion.arrive));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isDismissed) {
      !widget.animate || AppMotion.reduced(context)
          ? _c.value = 1
          : _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _t,
    axisAlignment: -1,
    child: FadeTransition(opacity: _t, child: widget.child),
  );
}
