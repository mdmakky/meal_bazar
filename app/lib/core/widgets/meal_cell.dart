import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';

/// One member × meal type: 1, ½, 0 (dimmed), Off (struck dash), `+n` guests.
/// Tap / long-press are handed to the caller (it applies `cycleMeal` or
/// opens the Off / Guest / custom sheet). Null handlers = read-only.
class MealCell extends StatelessWidget {
  const MealCell({
    super.key,
    required this.label,
    this.count = 0,
    this.guests = 0,
    this.off = false,
    this.today = false,
    this.banglaDigits = false,
    this.onTap,
    this.onLongPress,
  });

  /// "Member meal-type", read before the value by TalkBack.
  final String label;
  final double count;
  final int guests;
  final bool off;

  /// Today's column: the accent wash.
  final bool today;
  final bool banglaDigits;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final value = off ? '—' : Fmt.meals(count, banglaDigits: banglaDigits);
    final guestText = '+${Fmt.digits('$guests', bangla: banglaDigits)}';
    final spoken = [
      off ? l.mealCellOff : value,
      if (guests > 0) l.mealCellGuests(guestText),
    ].join(', ');

    final face = Text(
      value,
      key: ValueKey(value),
      style: text.titleSmall?.copyWith(
        color: off || count == 0 ? p.inkTertiary : p.ink,
        decoration: off ? TextDecoration.lineThrough : null,
        decorationColor: p.inkTertiary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    return Semantics(
      container: true,
      label: '$label: $spoken',
      button: onTap != null,
      excludeSemantics: true,
      child: Material(
        color: today ? p.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSize.mealCellWidth,
              minHeight: AppSize.touch,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.valueFade,
                  child: face,
                ),
                if (guests > 0)
                  Positioned(
                    top: AppSpace.xs,
                    right: AppSpace.xs,
                    child: Text(
                      guestText,
                      style: text.labelSmall?.copyWith(
                        color: p.inkSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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
