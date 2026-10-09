import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';

/// An unread count: a turmeric pill with dark ink, at least 22 dp round, the
/// digit centred. Bangla digits are tall, so the box sizes to the glyph and
/// ignores text scaling (it never clips "১"). Nothing when [count] is 0.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});

  final int count;

  static const double size = 22;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    final n = Fmt.digits(count > 99 ? '99+' : '$count', bangla: bn);
    return Semantics(
      label: AppLocalizations.of(context).homeUnreadCount(n),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: size, minHeight: size),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs + 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.palette.accent,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Text(
          n,
          textScaler: TextScaler.noScaling,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            // Dark ink on turmeric reads in both themes.
            color: AppPalette.light.ink,
            fontWeight: FontWeight.w700,
            height: 1.2,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}
