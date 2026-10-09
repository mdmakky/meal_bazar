import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../application/month_providers.dart';

/// Where the review screen of [start] lives.
String monthReviewPath(DateTime start) =>
    '/money/months/review?start=${isoDate(start)}';

/// Manager-only chip: the period waiting to be closed and how ready it is.
/// Stays until that period is closed; nothing while loading, on error, for
/// members, or when no month has ended.
class MonthStatusChip extends ConsumerWidget {
  const MonthStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null || !ref.watch(amIManagerProvider)) {
      return const SizedBox.shrink();
    }
    final s = ref.watch(monthStatusProvider(messId)).value;
    if (s == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final month = Fmt.monthName(
      s.start,
      locale: Localizations.localeOf(context).languageCode,
    );
    final (String label, Color color) = s.isClosed
        ? (l.monthEndChipClosed, p.advance)
        : s.isCorrecting
        ? (l.monthEndChipCorrecting, p.due)
        : s.needsAttention
        ? (l.monthEndChipAttention, p.due)
        : (l.monthEndChipClose(month), p.accent);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: const Key('monthStatusChip'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.go(monthReviewPath(s.start)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSize.touch,
            maxWidth: 170,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
