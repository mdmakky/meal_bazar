import 'package:flutter/material.dart';

import '../../../core/failure_text.dart';
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

/// A failed action: names the problem in an [AppSnack] with an error icon.
void snackFailure(BuildContext context, Object error) => AppSnack.show(
  context,
  failureText(context, error),
  icon: Icons.error_outline,
);

/// A member's initial in a small muted circle (grid rows, month list).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 28});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initial = name.trim().characters.firstOrNull?.toUpperCase() ?? '?';
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: p.surfaceMuted,
        ),
        child: Text(
          initial,
          textScaler: TextScaler.noScaling,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: p.inkSecondary,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// A 48 dp round button with a muted face that scales on press with a
/// selection click. Null [onPressed] = disabled (hairline, tertiary icon).
class RoundStepButton extends StatelessWidget {
  const RoundStepButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = onPressed != null;
    return PressableScale(
      enabled: on,
      haptic: on,
      scale: 0.88,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: p.surfaceMuted,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: p.ink,
          disabledForegroundColor: p.inkTertiary,
          side: on ? BorderSide.none : BorderSide(color: p.border),
        ),
        icon: Icon(icon, size: AppSize.spinner),
      ),
    );
  }
}

/// `−  value  +` with 48 dp targets. Null handler = that end is disabled.
/// The value pops when it changes.
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        spacing: AppSpace.xs,
        children: [
          Expanded(child: Text(label, style: text.bodyLarge)),
          RoundStepButton(
            tooltip: '${l.mealCellDecrease} $label',
            onPressed: onMinus,
            icon: Icons.remove,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: AppSize.touch),
            child: PopOnChange(
              value: value,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          RoundStepButton(
            tooltip: '${l.mealCellIncrease} $label',
            onPressed: onPlus,
            icon: Icons.add,
          ),
        ],
      ),
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
              runSpacing: AppSpace.sm,
              children: [
                for (final (label, e) in quick)
                  ChoiceChip(
                    label: Text(label),
                    selected: selected(e),
                    onSelected: (_) => set(e),
                  ),
              ],
            ),
            const Divider(height: AppSpace.sm),
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

/// One-tap choice as icon tiles, three across (the মিল FAB chooser).
/// Returns null when dismissed.
Future<T?> pickTile<T>(
  BuildContext context, {
  required String title,
  required List<(T, String, IconData)> options,
}) => AppSheet.show<T>(
  context,
  title: title,
  child: LayoutBuilder(
    builder: (context, c) {
      const gap = AppSpace.sm;
      final p = context.palette;
      final text = Theme.of(context).textTheme;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final (value, label, icon) in options)
            SizedBox(
              width: (c.maxWidth - gap * 2) / 3,
              child: PressableScale(
                haptic: true,
                child: Material(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, value),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 96),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.sm),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: AppSpace.sm,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.surfaceRaised,
                                boxShadow: AppElevation.button(p),
                              ),
                              child: Icon(
                                icon,
                                size: AppSize.spinner,
                                color: p.ink,
                              ),
                            ),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: text.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  ),
);
