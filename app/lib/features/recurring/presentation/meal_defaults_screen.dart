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
import '../../mess/presentation/common.dart';
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
      if (mounted) showFailure(context, e);
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.sm),
          child: Text(
            l.mealDefaultHelp,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        for (final m in members) ...[
          SectionTitle(m.displayName),
          for (final t in types)
            stepper((memberId: m.id, mealTypeId: t.id), t.name),
        ],
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }
}
