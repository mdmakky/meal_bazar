import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../motion/effects.dart';
import '../theme/tokens.dart';

/// A muted block standing in for content. Compose them into the shape of
/// what is loading and wrap the lot in one [SkeletonPulse].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.palette.surfaceMuted,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// The default skeleton: a title, a hero figure card and [rows] list rows,
/// pulsing calmly (opacity .55 ↔ 1, 1200 ms). No shimmer.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: SkeletonPulse(
        // Clips instead of overflowing when the slot is shorter than rows.
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.md,
            children: [
              const SkeletonBox(height: AppSpace.lg, width: AppSpace.xxxl * 2),
              const SkeletonBox(
                height: AppSpace.xxxl + AppSpace.xxl,
                radius: AppRadius.xl,
              ),
              const SizedBox(height: AppSpace.sm),
              for (var i = 0; i < rows; i++)
                const SkeletonBox(
                  height: AppSpace.xxxl + AppSpace.lg,
                  radius: AppRadius.md,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
