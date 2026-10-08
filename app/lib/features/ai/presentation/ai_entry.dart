import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/dates.dart';
import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../meals/application/meal_providers.dart';
import '../../meals/domain/meal.dart';
import '../../meals/presentation/meal_widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../money/domain/money.dart';
import '../data/ai_client.dart';
import '../domain/ai_draft.dart';

export '../domain/ai_draft.dart' show BazarDraft, BazarDraftItem;

/// Type a sentence, get an AI draft, review it, Confirm All. Nothing is saved
/// before Confirm All; rows go through the meal controller with source 'ai'.
Future<void> showMealDraftSheet(
  BuildContext context, {
  required DateTime day,
}) async {
  final l = AppLocalizations.of(context);
  final bn = bnDigits(context);
  final messenger = ScaffoldMessenger.of(context);
  final saved = await AppSheet.show<int>(
    context,
    title: l.aiMealTitle,
    child: _MealDraftBody(day: dayOnly(day)),
  );
  if (saved != null && saved > 0) {
    messenger.showSnackBar(
      SnackBar(content: Text(l.aiMealsSaved(Fmt.digits('$saved', bangla: bn)))),
    );
  }
}

/// Camera / gallery → compressed JPEG → AI draft → review. Returns the
/// confirmed items and chosen total, or null. Saves nothing itself.
Future<BazarDraft?> scanBazarReceipt(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final source = await pickOne<ImageSource>(
    context,
    title: l.aiScanTitle,
    options: [
      (ImageSource.camera, l.aiCamera),
      (ImageSource.gallery, l.aiGallery),
    ],
  );
  if (source == null || !context.mounted) return null;
  final Uint8List bytes;
  try {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 70,
    );
    if (file == null) return null;
    bytes = await file.readAsBytes();
  } catch (e) {
    // Permission denied, no camera, …: say so and let the user type it in.
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureText(context, e))));
    }
    return null;
  }
  if (!context.mounted) return null;
  return AppSheet.show<BazarDraft>(
    context,
    title: l.aiScanTitle,
    child: _BazarDraftBody(bytes: bytes),
  );
}

/// Calm text for "AI can't help right now" and any other failure.
String _problemText(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
  if (error is! AiUnavailable) return failureText(context, error);
  return switch (error.reason) {
    'disabled' => l.aiUnavailableDisabled,
    'quota' => l.aiUnavailableQuota,
    _ => l.aiUnavailableProviders,
  };
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      spacing: AppSpace.sm,
      children: [
        Icon(Icons.info_outline, size: AppSize.spinner, color: p.inkSecondary),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: p.inkSecondary),
          ),
        ),
      ],
    );
  }
}

/// Accent dot + "AI খসড়া".
class _DraftLabel extends StatelessWidget {
  const _DraftLabel();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      spacing: AppSpace.xs,
      children: [
        Container(
          width: AppSize.dot,
          height: AppSize.dot,
          decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
        ),
        Text(
          AppLocalizations.of(context).aiDraftLabel,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: p.inkSecondary),
        ),
      ],
    );
  }
}

/// AI content row: accentSoft wash.
class _DraftRow extends StatelessWidget {
  const _DraftRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.only(start: AppSpace.md),
    decoration: BoxDecoration(
      color: context.palette.accentSoft,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: child,
  );
}

// ── meal draft ─────────────────────────────────────────────────────────────

class _MealDraftBody extends ConsumerStatefulWidget {
  const _MealDraftBody({required this.day});

  final DateTime day;

  @override
  ConsumerState<_MealDraftBody> createState() => _MealDraftBodyState();
}

class _MealDraftBodyState extends ConsumerState<_MealDraftBody> {
  final _text = TextEditingController();
  bool _busy = false;
  Object? _problem;
  List<MealEntry>? _rows;
  List<String> _unmatched = const [];
  int _saved = 0;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send(String messId) async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final d = await ref
          .read(aiClientProvider)
          .mealDraft(messId: messId, date: widget.day, text: text);
      if (!mounted) return;
      setState(() {
        _rows = [
          for (final e in d.entries)
            MealEntry(
              memberId: e.memberId,
              mealTypeId: e.mealTypeId,
              date: widget.day,
              count: e.count,
              guestCount: e.guestCount,
              isOff: e.isOff,
            ),
        ];
        _unmatched = d.unmatched;
      });
    } catch (e) {
      if (mounted) setState(() => _problem = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(String messId) async {
    final rows = _rows!;
    setState(() {
      _busy = true;
      _problem = null;
    });
    final meals = ref.read(mealControllerProvider);
    try {
      // Saved rows leave the list, so a retry after a failure won't repeat them.
      while (rows.isNotEmpty) {
        await meals.save(messId, rows.first, source: 'ai');
        _saved++;
        rows.removeAt(0);
      }
      if (mounted) Navigator.pop(context, _saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _problem = e;
          _busy = false;
        });
      }
    }
  }

  Future<void> _edit(int i, String title) async {
    final edited = await showMealEntrySheet(
      context,
      title: title,
      entry: _rows![i],
    );
    if (edited != null && mounted) setState(() => _rows![i] = edited);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final rows = _rows;
    final problem = _problem == null
        ? null
        : _Notice(_problemText(context, _problem!));

    if (rows == null || messId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(hintText: l.aiMealHint),
          ),
          ?problem,
          AppButton(
            label: l.aiSend,
            icon: Icons.auto_awesome_outlined,
            loading: _busy,
            onPressed: messId == null ? null : () => _send(messId),
          ),
        ],
      );
    }

    final bn = bnDigits(context);
    final names = {
      for (final m in ref.watch(membersProvider(messId)).value ?? const [])
        m.id: m.displayName,
    };
    final types = {
      for (final t in ref.watch(mealTypesProvider(messId)).value ?? const [])
        t.id: t.name,
    };
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        const _DraftLabel(),
        if (rows.isEmpty) _Notice(l.aiNoMeals),
        for (final (i, e) in rows.indexed)
          Builder(
            builder: (context) {
              final title =
                  '${names[e.memberId] ?? '?'} · ${types[e.mealTypeId] ?? '?'}';
              final value = [
                e.isOff ? l.mealCellOff : Fmt.meals(e.count, banglaDigits: bn),
                if (e.guestCount > 0)
                  l.mealCellGuests(Fmt.digits('${e.guestCount}', bangla: bn)),
              ].join(' · ');
              return _DraftRow(
                child: Row(
                  children: [
                    Expanded(
                      child: Text('$title · $value', style: text.bodyLarge),
                    ),
                    IconButton(
                      tooltip: l.aiEdit,
                      onPressed: _busy ? null : () => _edit(i, title),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: l.aiRemove,
                      onPressed: _busy
                          ? null
                          : () => setState(() => rows.removeAt(i)),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              );
            },
          ),
        if (_unmatched.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              border: Border.all(color: p.warning),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.xs,
              children: [
                Text(
                  l.aiUnmatchedNote,
                  style: text.bodyMedium?.copyWith(color: p.inkSecondary),
                ),
                for (final u in _unmatched) Text(u, style: text.bodyLarge),
              ],
            ),
          ),
        ?problem,
        const SizedBox(height: AppSpace.sm),
        Row(
          spacing: AppSpace.sm,
          children: [
            Expanded(
              child: AppButton(
                label: l.aiReject,
                variant: AppButtonVariant.secondary,
                onPressed: _busy ? null : () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: AppButton(
                label: l.aiConfirmAll,
                loading: _busy,
                onPressed: rows.isEmpty ? null : () => _confirm(messId),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── bazar draft ────────────────────────────────────────────────────────────

class _Item {
  _Item(this.source)
    : name = TextEditingController(text: source.name),
      price = TextEditingController(text: _plain(source.price));

  final BazarDraftItem source;
  final TextEditingController name;
  final TextEditingController price;

  static String _plain(double v) =>
      v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _BazarDraftBody extends ConsumerStatefulWidget {
  const _BazarDraftBody({required this.bytes});

  final Uint8List bytes;

  @override
  ConsumerState<_BazarDraftBody> createState() => _BazarDraftBodyState();
}

class _BazarDraftBodyState extends ConsumerState<_BazarDraftBody> {
  BazarDraft? _draft;
  Object? _problem;
  bool _notJpeg = false;
  List<_Item> _items = [];
  bool _useReceiptTotal = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final b = widget.bytes;
    // ponytail: the gateway takes JPEG only; a PNG/HEIC from the gallery is
    // refused here. Re-encode client-side if users hit this often.
    if (b.length < 2 || b[0] != 0xFF || b[1] != 0xD8) {
      setState(() => _notJpeg = true);
      return;
    }
    final messId = ref.read(currentMessIdProvider);
    setState(() => _problem = null);
    try {
      if (messId == null) throw const AiUnavailable('disabled');
      final d = await ref
          .read(aiClientProvider)
          .bazarDraft(
            messId: messId,
            date: today(),
            imageBase64: base64Encode(b),
          );
      if (!mounted) return;
      setState(() {
        _draft = d;
        _items = [for (final i in d.items) _Item(i)];
      });
    } catch (e) {
      if (mounted) setState(() => _problem = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final draft = _draft;
    if (_notJpeg) return _Notice(l.aiNotJpeg);
    if (_problem != null) {
      final problem = _problem!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          _Notice(_problemText(context, problem)),
          if (problem is! AiUnavailable)
            AppButton(
              label: l.retry,
              variant: AppButtonVariant.secondary,
              onPressed: _load,
            ),
        ],
      );
    }
    if (draft == null) return const LoadingView();

    final bn = bnDigits(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final prices = [for (final i in _items) parseAmount(i.price.text)];
    final valid =
        prices.every((v) => v != null) &&
        _items.every((i) => i.name.text.trim().isNotEmpty);
    final sum = valid ? itemsTotal(prices.cast<double>()) : null;
    final receipt = draft.total;
    final mismatch =
        sum != null && receipt != null && (sum - receipt).abs() >= 0.005;
    final total = mismatch
        ? (_useReceiptTotal ? receipt : sum)
        : (sum ?? receipt);
    String money(double v) => Fmt.money(v, banglaDigits: bn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        const _DraftLabel(),
        if (_items.isEmpty) _Notice(l.aiNoItems),
        for (final (i, item) in _items.indexed)
          _DraftRow(
            child: Row(
              spacing: AppSpace.sm,
              children: [
                Expanded(
                  child: TextField(
                    controller: item.name,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l.aiItemName,
                      helperText: [
                        if (item.source.qty != null)
                          Fmt.digits(
                            _Item._plain(item.source.qty!),
                            bangla: bn,
                          ),
                        ?item.source.unit,
                      ].join(' '),
                    ),
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: item.price,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l.aiItemPrice,
                      prefixText: '৳',
                      errorText: prices[i] == null ? '' : null,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.aiRemove,
                  onPressed: () => setState(() {
                    _items.removeAt(i).dispose();
                  }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        if (draft.notes.isNotEmpty) _Notice(draft.notes),
        if (mismatch) ...[
          Text(
            l.aiTotalMismatch,
            style: text.bodyMedium?.copyWith(color: p.warning),
          ),
          Wrap(
            spacing: AppSpace.sm,
            children: [
              ChoiceChip(
                label: Text(l.aiReceiptTotal(money(receipt))),
                selected: _useReceiptTotal,
                onSelected: (_) => setState(() => _useReceiptTotal = true),
              ),
              ChoiceChip(
                label: Text(l.aiItemsSum(money(sum))),
                selected: !_useReceiptTotal,
                onSelected: (_) => setState(() => _useReceiptTotal = false),
              ),
            ],
          ),
        ] else if (total != null)
          Text(l.aiItemsSum(money(total)), style: text.titleMedium),
        const SizedBox(height: AppSpace.sm),
        Row(
          spacing: AppSpace.sm,
          children: [
            Expanded(
              child: AppButton(
                label: l.aiReject,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: AppButton(
                label: l.aiUseDraft,
                onPressed: !valid || total == null
                    ? null
                    : () => Navigator.pop(
                        context,
                        BazarDraft(
                          items: [
                            for (final (j, it) in _items.indexed)
                              BazarDraftItem(
                                name: it.name.text.trim(),
                                qty: it.source.qty,
                                unit: it.source.unit,
                                price: prices[j]!,
                              ),
                          ],
                          total: total,
                          totalMatchesItems: total == sum,
                          notes: draft.notes,
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
