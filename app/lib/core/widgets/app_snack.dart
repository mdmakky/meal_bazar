import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Transient feedback: a floating ink pill (theme) with an icon; the content
/// rises 8 dp as the pill fades in. Use for undo after a delete, "saved".
abstract final class AppSnack {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context,
    String message, {
    IconData? icon = Icons.check_circle_outline,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final p = context.palette;
    Widget content = Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSize.spinner, color: p.onInk),
          const SizedBox(width: AppSpace.md),
        ],
        Expanded(child: Text(message)),
      ],
    );
    if (!AppMotion.reduced(context)) {
      content = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: AppMotion.base,
        curve: AppMotion.arrive,
        child: content,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, AppMotion.rise * t),
          child: child,
        ),
      );
    }
    return messenger.showSnackBar(
      SnackBar(
        content: content,
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
  }
}
