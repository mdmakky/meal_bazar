import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart';
import '../application/duty_providers.dart';

/// Who has bazar duty today and tomorrow, for the Home screen. Renders
/// nothing while loading, on error, or when nobody is on duty.
class TodayDutyCard extends ConsumerWidget {
  const TodayDutyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messId = ref.watch(currentMessIdProvider);
    if (messId == null) return const SizedBox.shrink();
    final t = today();
    final tomorrow = DateTime(t.year, t.month, t.day + 1);
    final duties = ref.watch(dutiesProvider((messId, t, tomorrow))).value;
    if (duties == null || duties.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final me = ref.watch(currentMembershipProvider)?.member.id;
    final names = {
      for (final m in ref.watch(membersProvider(messId)).value ?? const [])
        m.id: m.displayName,
    };
    final myToday = duties
        .where((d) => d.date == t && d.memberId == me)
        .firstOrNull;

    String line(DateTime day) {
      final on = duties.where((d) => d.date == day);
      if (on.isEmpty) return '';
      if (on.any((d) => d.memberId == me)) {
        return day == t ? l.dutyTodayMine : l.dutyTomorrowMine;
      }
      final who = on.map((d) => names[d.memberId] ?? '').join(', ');
      return day == t ? l.dutyTodayOther(who) : l.dutyTomorrowOther(who);
    }

    final lines = [line(t), line(tomorrow)].where((s) => s.isNotEmpty);

    return AppCard(
      onTap: () => context.push('/more/duty'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.md,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            color: myToday != null ? p.accent : p.inkSecondary,
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
                  myToday.done
                      ? Text(
                          l.dutyDone,
                          style: text.bodyMedium?.copyWith(color: p.advance),
                        )
                      : Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AppButton(
                            label: l.dutyMarkDone,
                            icon: Icons.check,
                            variant: AppButtonVariant.secondary,
                            onPressed: () async {
                              try {
                                await ref
                                    .read(dutyControllerProvider)
                                    .setDone(myToday, true);
                              } catch (e) {
                                if (context.mounted) showFailure(context, e);
                              }
                            },
                          ),
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
