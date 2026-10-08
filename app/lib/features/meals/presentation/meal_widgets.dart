import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/meal.dart';

/// Bangla digits follow the UI language.
bool bnDigits(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'bn';

/// Plain decimal, trailing zeros trimmed: 20.5, 0.25, 3.
String decimal(num v, {required bool bangla}) => Fmt.digits(
  v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
  bangla: bangla,
);

/// `−  value  +` with 48 dp targets. Null handler = that end is disabled.
class CountStepper extends StatelessWidget {
  const CountStepper({
    super.key,
    required this.label,
    required this.value,
    this.onMinus,
    this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: text.bodyLarge)),
        IconButton(
          tooltip: '${l.mealCellDecrease} $label',
          onPressed: onMinus,
          icon: const Icon(Icons.remove),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppSize.touch),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton(
          tooltip: '${l.mealCellIncrease} $label',
          onPressed: onPlus,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// Long-press editor for one cell: ১ / ½ / ০ / Off, own count in ½ steps up to
/// 5, guests 0–20. Returns the edited entry, or null when dismissed.
Future<MealEntry?> showMealEntrySheet(
  BuildContext context, {
  required String title,
  required MealEntry entry,
  bool guestsFirst = false,
}) {
  final l = AppLocalizations.of(context);
  final bn = bnDigits(context);
  var draft = entry;
  return AppSheet.show<MealEntry>(
    context,
    title: title,
    actions: [
      Builder(
        builder: (context) => AppButton(
          label: l.mealCellSave,
          onPressed: () => Navigator.pop(context, draft),
        ),
      ),
    ],
    child: StatefulBuilder(
      builder: (context, setState) {
        void set(MealEntry e) => setState(() => draft = e);
        final quick = <(String, MealEntry)>[
          (
            Fmt.meals(1, banglaDigits: bn),
            draft.copyWith(count: 1, isOff: false),
          ),
          (
            Fmt.meals(0.5, banglaDigits: bn),
            draft.copyWith(count: 0.5, isOff: false),
          ),
          (
            Fmt.meals(0, banglaDigits: bn),
            draft.copyWith(count: 0, isOff: false),
          ),
          (l.mealCellOff, draft.copyWith(count: 0, isOff: true)),
        ];
        bool selected(MealEntry e) =>
            e.isOff == draft.isOff && (e.isOff || e.count == draft.count);
        final own = CountStepper(
          label: l.mealCellOwn,
          value: draft.isOff ? '—' : Fmt.meals(draft.count, banglaDigits: bn),
          onMinus: draft.isOff || draft.count <= 0
              ? null
              : () => set(draft.copyWith(count: draft.count - 0.5)),
          onPlus: draft.isOff || draft.count >= 5
              ? null
              : () => set(draft.copyWith(count: draft.count + 0.5)),
        );
        final guests = CountStepper(
          label: l.mealCellGuestsLabel,
          value: Fmt.digits('${draft.guestCount}', bangla: bn),
          onMinus: draft.guestCount <= 0
              ? null
              : () => set(draft.copyWith(guestCount: draft.guestCount - 1)),
          onPlus: draft.guestCount >= 20
              ? null
              : () => set(draft.copyWith(guestCount: draft.guestCount + 1)),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            Wrap(
              spacing: AppSpace.sm,
              children: [
                for (final (label, e) in quick)
                  ChoiceChip(
                    label: Text(label),
                    selected: selected(e),
                    onSelected: (_) => set(e),
                  ),
              ],
            ),
            if (guestsFirst) ...[guests, own] else ...[own, guests],
          ],
        );
      },
    ),
  );
}

/// One-tap choice from a short list. Returns null when dismissed.
Future<T?> pickOne<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
}) => AppSheet.show<T>(
  context,
  title: title,
  child: Column(
    children: [
      for (final (value, label) in options)
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: AppSize.touch,
          title: Text(label),
          onTap: () => Navigator.pop(context, value),
        ),
    ],
  ),
);
