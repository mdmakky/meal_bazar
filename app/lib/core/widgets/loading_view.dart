import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';

/// Hairline skeleton blocks. No shimmer.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget block(double height, {double? width}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.md,
          children: [
            block(AppSpace.lg, width: AppSpace.xxxl * 2),
            block(AppSpace.xxxl, width: AppSpace.xxxl * 3),
            const SizedBox(height: AppSpace.sm),
            for (var i = 0; i < rows; i++) block(AppSpace.xxxl + AppSpace.lg),
          ],
        ),
      ),
    );
  }
}
