import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

/// Names the problem and the recovery. Defaults to the generic message.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.lg,
          children: [
            Icon(
              Icons.error_outline,
              size: AppSize.emptyIcon,
              color: context.palette.due,
            ),
            Text(
              message ?? l.genericError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            AppButton(
              label: l.retry,
              icon: Icons.refresh,
              onPressed: onRetry,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
