import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Flat surface, 1 px border, radius 12, 16 padding. Never nest cards.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return Card(
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}
