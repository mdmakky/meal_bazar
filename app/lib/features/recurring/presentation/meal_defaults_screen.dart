import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../meals/application/meal_providers.dart';
import '../../meals/domain/meal.dart';
import '../../meals/presentation/meal_widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/domain/member.dart';
import '../application/recurring_providers.dart';
import '../domain/recurring.dart';

/// Manager: each active member's default meals per enabled meal type (0–5 in
/// ½ steps). "Fill today" uses them when there is no meal the day before.
class MealDefaultsScreen extends ConsumerStatefulWidget {
  const MealDefaultsScreen({super.key});

  @override
  ConsumerState<MealDefaultsScreen> createState() => _MealDefaultsScreenState();
}

class _MealDefaultsScreenState extends ConsumerState<MealDefaultsScreen> {
  /// Optimistic values while saving, over the server map.
  final _pending = <MealDefaultKey, double>{};

  Future<void> _set(String messId, MealDefaultKey key, double count) async {
    setState(() => _pending[key] = count);
    try {
      await ref
          .read(recurringControllerProvider)
          .setMealDefault(messId, key, count);
    } catch (e) {
      if (mounted) snackFailure(context, e);
    } finally {
      if (mounted) setState(() => _pending.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);

    final Widget body;
    if (messId == null) {
      body = const LoadingView();
    } else if (!ref.watch(amIManagerProvider)) {
      body = EmptyView(
        icon: Icons.lock_outline,
        message: l.mealDefaultManagerOnly,
      );
    } else {
      final all = [
        ref.watch(membersProvider(messId)),
        ref.watch(mealTypesProvider(messId)),
        ref.watch(mealDefaultsProvider(messId)),
      ];
      final error = all.where((a) => a.hasError).firstOrNull?.error;
      if (error != null) {
        body = ErrorView(
          message: failureText(context, error),
          onRetry: () {
            ref.invalidate(membersProvider(messId));
            ref.invalidate(mealTypesProvider(messId));
            ref.invalidate(mealDefaultsProvider(messId));
          },
        );
      } else if (all.any((a) => !a.hasValue)) {
        body = const LoadingView();
      } else {
        final members = ref
            .watch(membersProvider(messId))
            .requireValue
            .where((m) => m.status == MemberStatus.active)
            .toList();
        final types = ref
            .watch(mealTypesProvider(messId))
            .requireValue
            .where((t) => t.enabled)
            .toList();
        final saved = ref.watch(mealDefaultsProvider(messId)).requireValue;
        body = members.isEmpty || types.isEmpty
            ? EmptyView(
                icon: Icons.restaurant_outlined,
                message: l.mealDefaultEmpty,
              )
            : _list(messId, members, types, {...saved, ..._pending});
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.mealDefaultTitle)),
      body: body,
    );
  }

  Widget _list(
    String messId,
    List<Member> members,
    List<MealType> types,
    Map<MealDefaultKey, double> values,
  ) {
    final l = AppLocalizations.of(context);
    final bn = bnDigits(context);
    Widget stepper(MealDefaultKey key, String label) {
      final v = values[key] ?? 1;
      return CountStepper(
        label: label,
        value: decimal(v, bangla: bn),
        onMinus: v <= 0 ? null : () => _set(messId, key, v - 0.5),
        onPlus: v >= 5 ? null : () => _set(messId, key, v + 0.5),
      );
    }

    return StaggeredList(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
        children: [
          _AutoMealsCard(messId: messId),
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.sm),
            child: Text(
              l.mealDefaultHelp,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          ...StaggeredList.wrap([
            for (final m in members)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: AppCard.raised(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.md,
                    AppSpace.sm,
                    AppSpace.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        spacing: AppSpace.md,
                        children: [
                          InitialsAvatar(m.displayName, size: 32),
                          Expanded(
                            child: Text(
                              m.displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      for (final t in types)
                        stepper((memberId: m.id, mealTypeId: t.id), t.name),
                    ],
                  ),
                ),
              ),
          ]),
          const SizedBox(height: AppSpace.xl),
        ],
      ),
    );
  }
}

/// Switch for the automatic fill after midnight, with what the last run did.
/// The pattern it uses is the list below (default 1 where none is set).
class _AutoMealsCard extends ConsumerWidget {
  const _AutoMealsCard({required this.messId});

  final String messId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mess = ref.watch(currentMessProvider);
    final text = Theme.of(context).textTheme;
    final last = mess?.autoMealsLastDate;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: AppCard.raised(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.autoMealsTitle, style: text.titleSmall),
              subtitle: Text(l.autoMealsBody),
              value: mess?.autoMeals ?? false,
              onChanged: mess == null
                  ? null
                  : (on) async {
                      try {
                        await ref
                            .read(messControllerProvider)
                            .setAutoMeals(messId, on);
                      } catch (e) {
                        if (context.mounted) snackFailure(context, e);
                      }
                    },
            ),
            if (mess?.autoMeals ?? false)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Text(
                  last == null
                      ? l.autoMealsNever
                      : l.autoMealsLast(
                          Fmt.digits(
                            last.split('-').reversed.take(2).join('/'),
                            bangla: bnDigits(context),
                          ),
                          Fmt.digits(
                            '${mess?.autoMealsLastCount ?? 0}',
                            bangla: bnDigits(context),
                          ),
                        ),
                  style: text.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
