import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';

enum AppButtonVariant { primary, secondary, text }

/// Height 48, radius 12 (from theme). Loading swaps the label for a spinner
/// at the same width and ignores taps.
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
        Visibility(
          visible: !loading,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: content,
        ),
        if (loading)
          Builder(
            builder: (context) => SizedBox.square(
              dimension: AppSize.spinner,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DefaultTextStyle.of(context).style.color,
                semanticsLabel: AppLocalizations.of(context).loading,
              ),
            ),
          ),
      ],
    );
    // While loading keep the enabled look but swallow taps.
    final tap = loading ? (onPressed == null ? null : () {}) : onPressed;
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: tap, child: child),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: tap,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: tap, child: child),
    };
    final guarded = IgnorePointer(ignoring: loading, child: button);
    return expand ? SizedBox(width: double.infinity, child: guarded) : guarded;
  }
}
