import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum AppCardVariant {
  /// Flat surface with a 1 px hairline, radius 12. Lists, settings rows.
  plain,

  /// White lifted off the warm page by layered soft shadows, no outline.
  raised,

  /// The statement card: ink (dark: raised #23221F + hairline), radius 24,
  /// 24 padding. One per screen, for the headline figure. Children read
  /// colours and text styles from [AppPalette.statement] automatically.
  ink,
}

/// Never nest cards.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.variant = AppCardVariant.plain,
    EdgeInsetsGeometry? padding,
  }) : padding =
           padding ??
           (variant == AppCardVariant.ink
               ? const EdgeInsets.all(AppSpace.xl)
               : const EdgeInsets.all(AppSpace.lg));

  /// `AppCard.raised(child: ...)`.
  const AppCard.raised({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.lg),
  }) : variant = AppCardVariant.raised;

  /// The statement card: `AppCard.ink(child: ...)`.
  const AppCard.ink({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.xl),
  }) : variant = AppCardVariant.ink;

  final Widget child;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    if (variant == AppCardVariant.plain) {
      return Card(
        child: onTap == null ? body : InkWell(onTap: onTap, child: body),
      );
    }

    final p = context.palette;
    final brightness = Theme.of(context).brightness;
    final ink = variant == AppCardVariant.ink;
    final radius = BorderRadius.circular(ink ? AppRadius.xl : AppRadius.md);
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppElevation.raised(p),
      ),
      child: Material(
        color: ink ? p.surfaceInk : p.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: ink && brightness == Brightness.dark
              ? BorderSide(color: p.surfaceInkBorder)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? body : InkWell(onTap: onTap, child: body),
      ),
    );
    if (ink) {
      card = Theme(data: AppTheme.statement(brightness), child: card);
    }
    return card;
  }
}
