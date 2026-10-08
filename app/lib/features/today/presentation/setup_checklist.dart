import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/prefs.dart';
import '../../../core/widgets/widgets.dart';
import '../../meals/presentation/meal_widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../../money/application/money_providers.dart';
import '../../money/presentation/money_sheets.dart';
import '../../month/application/month_providers.dart';

/// Device flag: the manager opened the meal types screen.
const setupFlagMealTypes = 'setup.mealTypes';

/// Device flag: "পরে করব" hid the checklist for this mess.
const setupFlagDismissed = 'setup.dismissed';

/// First-run checklist at the top of হোম (managers). Each step is derived
/// from real data; hidden once all are done, dismissed, or still loading.
class SetupChecklist extends ConsumerWidget {
  const SetupChecklist({super.key, required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final flags = ref.watch(messFlagsProvider(messId)).value;
    final members = ref.watch(membersProvider(messId)).value;
    final deposits = ref.watch(depositsProvider(messId)).value;
    final totals = ref.watch(monthTotalsProvider(messId)).value;
    if (flags == null ||
        members == null ||
        deposits == null ||
        totals == null ||
        flags.contains(setupFlagDismissed)) {
      return const SizedBox.shrink();
    }
    final steps = <(String, bool, VoidCallback?)>[
      (l.setupMess, true, null),
      (
        l.setupMealTypes,
        flags.contains(setupFlagMealTypes),
        () => context.push('/more/meal-types'),
      ),
      (
        l.setupMembers,
        members.where((m) => m.status != MemberStatus.pending).length >= 2,
        () => context.push('/more/members'),
      ),
      (
        l.setupDeposit,
        deposits.items.isNotEmpty,
        () => showAddDepositSheet(context),
      ),
      (l.setupMeals, totals.totalMeals > 0, () => context.go('/meals')),
    ];
    final done = steps.where((s) => s.$2).length;
    if (done == steps.length) return const SizedBox.shrink();
    final current = steps.indexWhere((s) => !s.$2);
    final bn = bnDigits(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        0,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.sm,
          children: [
            Row(
              children: [
                Expanded(child: Text(l.setupTitle, style: text.titleMedium)),
                TextButton(
                  onPressed: () => setMessFlag(ref, messId, setupFlagDismissed),
                  child: Text(l.setupLater),
                ),
              ],
            ),
            Text(
              l.setupProgress(
                Fmt.digits('$done', bangla: bn),
                Fmt.digits('${steps.length}', bangla: bn),
              ),
              style: text.bodyMedium?.copyWith(color: p.inkSecondary),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: done / steps.length,
                minHeight: AppSpace.xs,
                color: p.ink,
                backgroundColor: p.surfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            for (final (i, (label, ok, go)) in steps.indexed)
              _StepRow(
                number: Fmt.digits('${i + 1}', bangla: bn),
                label: label,
                done: ok,
                current: i == current,
                onStart: i == current ? go : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.label,
    required this.done,
    required this.current,
    this.onStart,
  });

  final String number;
  final String label;
  final bool done;
  final bool current;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.touch),
      child: Row(
        spacing: AppSpace.md,
        children: [
          Container(
            width: AppSize.stepFace,
            height: AppSize.stepFace,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? p.ink : null,
              border: done
                  ? null
                  : Border.all(
                      color: current ? p.accent : p.borderStrong,
                      width: current ? 2 : AppSize.hairline,
                    ),
            ),
            child: done
                ? Icon(Icons.check, size: AppSize.dot * 2, color: p.onInk)
                : Text(number, style: text.labelMedium),
          ),
          Expanded(
            child: Text(
              label,
              style: text.bodyLarge?.copyWith(
                color: done ? p.inkTertiary : p.ink,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: p.inkTertiary,
              ),
            ),
          ),
          if (onStart != null)
            AppButton(
              label: AppLocalizations.of(context).setupStart,
              onPressed: onStart,
            ),
        ],
      ),
    );
  }
}
