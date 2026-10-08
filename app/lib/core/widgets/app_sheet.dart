import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Modal bottom sheet: drag handle, title, scrollable body, sticky actions.
/// Lifts above the keyboard.
abstract final class AppSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    List<Widget> actions = const [],
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                0,
                AppSpace.gutter,
                AppSpace.md,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.gutter,
                ),
                child: child,
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpace.gutter),
                child: Row(
                  spacing: AppSpace.sm,
                  children: [for (final a in actions) Expanded(child: a)],
                ),
              )
            else
              const SizedBox(height: AppSpace.gutter),
          ],
        ),
      ),
    );
  }
}
