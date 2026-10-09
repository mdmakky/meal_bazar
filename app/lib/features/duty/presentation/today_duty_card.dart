import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart';
import '../../money/presentation/money_sheets.dart'
    show showBazarForm, showBazarRequestForm;
import '../application/duty_providers.dart';
import '../domain/duty.dart';

/// Who has bazar duty today, tomorrow and the day after, for the Home
/// screen. Renders nothing while loading, on error, or when nobody is on
/// duty in those three days.
class TodayDutyCard extends ConsumerWidget {
  const TodayDutyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null || !ref.featureOn('duty')) {
      return const SizedBox.shrink();
    }
    final t = today();
    final days = [
      for (var i = 0; i < 3; i++) DateTime(t.year, t.month, t.day + i),
    ];
    final duties = ref.watch(dutiesProvider((messId, t, days.last))).value;
    if (duties == null || duties.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final me = ref.watch(currentMembershipProvider)?.member.id;
    final manager = ref.watch(amIManagerProvider);
    final names = <String, String>{
      for (final m in ref.watch(membersProvider(messId)).value ?? const [])
        m.id: m.displayName,
    };
    final myToday = duties
        .where((d) => d.date == t && d.memberId == me)
        .firstOrNull;
    // A manager writes the bazar itself; a member sends it for approval.
    final canSubmit = manager || ref.featureOn('member_bazar');

    final lines = [
      for (final (i, day) in days.indexed)
        if (dutyLine(
              l,
              i,
              duties.where((d) => d.date == day),
              me: me,
              names: names,
            )
            case final s?)
          s,
    ];

    // Home's card rhythm: each block owns the 16 dp below it.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        AppSpace.lg,
      ),
      child: AppCard.raised(
        onTap: () => context.push('/more/duty'),
        padding: const EdgeInsets.all(AppSpace.md),
        // Compact: the lines sit centred on the icon, no empty foot.
        child: Row(
          spacing: AppSpace.md,
          children: [
            // Turmeric only when the duty is mine today (live).
            CircleAvatar(
              radius: 20,
              backgroundColor: myToday != null ? p.accentSoft : p.surfaceMuted,
              child: Icon(
                Icons.shopping_basket_outlined,
                size: 20,
                color: myToday != null ? p.accent : p.inkSecondary,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.xs,
                children: [
                  for (final (i, s) in lines.indexed)
                    Text(
                      s,
                      style: i == 0
                          ? text.titleSmall
                          : text.bodyMedium?.copyWith(color: p.inkSecondary),
                    ),
                  if (myToday != null)
                    AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.base),
                      child: myToday.done
                          ? Text(
                              l.dutyDone,
                              key: const ValueKey('done'),
                              style: text.bodyMedium?.copyWith(
                                color: p.advance,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(top: AppSpace.xs),
                              child: Wrap(
                                spacing: AppSpace.sm,
                                runSpacing: AppSpace.sm,
                                children: [
                                  if (canSubmit)
                                    AppButton(
                                      label: l.bazarReqTitle,
                                      icon: Icons.receipt_long_outlined,
                                      onPressed: () => _submit(
                                        context,
                                        ref,
                                        myToday,
                                        manager: manager,
                                      ),
                                    ),
                                  AppButton(
                                    label: l.dutyMarkDone,
                                    icon: Icons.check,
                                    variant: AppButtonVariant.secondary,
                                    onPressed: () =>
                                        _markDone(context, ref, myToday),
                                  ),
                                ],
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Submitting the bazar is doing the duty: once it is sent (or, for a
  /// manager, saved) the duty is ticked too.
  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    BazarDuty duty, {
    required bool manager,
  }) async {
    final open = manager ? showBazarForm : showBazarRequestForm;
    final sent = await open(context);
    if (!sent || !context.mounted) return;
    // Best effort: the bazar is in; the tick can still be done by hand.
    ref
        .read(dutyControllerProvider)
        .setDone(duty, true)
        .catchError((Object e) => debugPrint('duty done: $e'));
  }

  Future<void> _markDone(
    BuildContext context,
    WidgetRef ref,
    BazarDuty duty,
  ) async {
    try {
      await ref.read(dutyControllerProvider).setDone(duty, true);
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }
}

/// Day [offset] (0 today, 1 tomorrow, 2 the day after): who does the bazar,
/// "you" when it is [me]. Null when nobody is on duty that day.
String? dutyLine(
  AppLocalizations l,
  int offset,
  Iterable<BazarDuty> on, {
  required String? me,
  required Map<String, String> names,
}) {
  if (on.isEmpty) return null;
  if (on.any((d) => d.memberId == me)) {
    return switch (offset) {
      0 => l.dutyTodayMine,
      1 => l.dutyTomorrowMine,
      _ => l.dutyDayAfterMine,
    };
  }
  final who = on.map((d) => names[d.memberId] ?? '').join(', ');
  return switch (offset) {
    0 => l.dutyTodayOther(who),
    1 => l.dutyTomorrowOther(who),
    _ => l.dutyDayAfterOther(who),
  };
}
