import 'package:flutter/material.dart';

import '../format.dart';
import '../theme/tokens.dart';

/// ৳ amount with tabular figures. `signed: true` colors < 0 due, > 0 advance.
class Money extends StatelessWidget {
  const Money(
    this.amount, {
    super.key,
    this.signed = false,
    this.banglaDigits = false,
    this.style,
  });

  final num amount;
  final bool signed;
  final bool banglaDigits;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Fmt.money(amount, banglaDigits: banglaDigits);
    final color = !signed || amount == 0
        ? null
        : amount < 0
        ? palette.due
        : palette.advance;
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
