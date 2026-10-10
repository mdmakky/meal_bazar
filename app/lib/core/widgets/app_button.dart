import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../motion/effects.dart';
import '../theme/tokens.dart';

enum AppButtonVariant { primary, secondary, accent, text }

/// Height 48, radius 12 (from theme). Presses scale to 0.96. Loading
/// cross-fades the label to a spinner at the same width and ignores taps.
/// Primary is filled ink with a soft lift (light theme); secondary is raised
/// white with a hairline.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final fade = AppMotion.of(context, AppMotion.fast);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSize.spinner),
          const SizedBox(width: AppSpace.sm),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    final child = Stack(
      alignment: Alignment.center,
      children: [
        // Stays in layout to keep the width; fades instead of vanishing.
        AnimatedOpacity(
          opacity: loading ? 0 : 1,
          duration: fade,
          curve: AppMotion.state,
          child: content,
        ),
        if (loading)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: fade,
            builder: (context, t, child) => Opacity(opacity: t, child: child),
            child: Builder(
              builder: (context) => SizedBox.square(
                dimension: AppSize.spinner,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DefaultTextStyle.of(context).style.color,
                  semanticsLabel: AppLocalizations.of(context).loading,
                ),
              ),
            ),
          ),
      ],
    );
    // While loading keep the enabled look but swallow taps.
    final tap = loading ? (onPressed == null ? null : () {}) : onPressed;
    final enabled = onPressed != null;
    Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: tap, child: child),
      // The one warm, decisive action next to a quiet one (e.g. Verify).
      AppButtonVariant.accent => FilledButton(
        onPressed: tap,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).extension<AppPalette>()?.accent,
          foregroundColor: const Color(0xFF141413),
        ),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: tap,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: tap, child: child),
    };
    // Palette is absent only under a bare MaterialApp (some tests).
    final palette = Theme.of(context).extension<AppPalette>();
    final lifted =
        palette != null &&
        enabled &&
        variant != AppButtonVariant.text &&
        Theme.of(context).brightness == Brightness.light;
    if (lifted) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppElevation.button(palette),
        ),
        child: button,
      );
    }
    final guarded = IgnorePointer(
      ignoring: loading,
      child: PressableScale(enabled: enabled && !loading, child: button),
    );
    return expand ? SizedBox(width: double.infinity, child: guarded) : guarded;
  }
}
