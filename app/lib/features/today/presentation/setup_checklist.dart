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
      child: AppCard.raised(
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
            _Progress(value: done / steps.length),
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
                ? _DrawnCheck(color: p.onInk)
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

/// Ink fill that grows to [value] from where it was.
class _Progress extends StatelessWidget {
  const _Progress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: ColoredBox(
        color: p.surfaceMuted,
        child: SizedBox(
          height: AppSpace.sm,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: AppMotion.of(context, AppMotion.slow * 2),
            curve: AppMotion.arrive,
            builder: (context, v, _) => FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: p.ink,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A check that draws itself, short stroke then long, once on mount.
class _DrawnCheck extends StatelessWidget {
  const _DrawnCheck({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.of(context, AppMotion.slow),
    curve: AppMotion.arrive,
    builder: (context, t, _) => CustomPaint(
      size: const Size.square(AppSize.dot * 2),
      painter: _CheckPainter(t, color),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.16, w * 0.54)
      ..lineTo(w * 0.42, w * 0.78)
      ..lineTo(w * 0.86, w * 0.26);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t || old.color != color;
}
