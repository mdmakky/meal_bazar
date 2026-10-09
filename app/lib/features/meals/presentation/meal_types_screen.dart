import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/prefs.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart';
import '../../today/presentation/setup_checklist.dart' show setupFlagMealTypes;
import '../application/meal_providers.dart';
import '../domain/meal.dart';
import 'meal_widgets.dart';

/// Manager: enable, rename, weigh (0–5, ¼ steps), reorder and add meal types.
class MealTypesScreen extends ConsumerStatefulWidget {
  const MealTypesScreen({super.key});

  @override
  ConsumerState<MealTypesScreen> createState() => _MealTypesScreenState();
}

class _MealTypesScreenState extends ConsumerState<MealTypesScreen> {
  /// Optimistic copy while a change is saving; null = show the server list.
  List<MealType>? _items;

  @override
  void initState() {
    super.initState();
    // Setup checklist: visiting here counts as "meal times set up".
    final messId = ref.read(currentMessIdProvider);
    if (messId != null) setMessFlag(ref, messId, setupFlagMealTypes);
  }

  MealType _with(MealType t, {String? name, double? weight, bool? enabled}) =>
      MealType(
        id: t.id,
        messId: t.messId,
        name: name ?? t.name,
        sortOrder: t.sortOrder,
        weight: weight ?? t.weight,
        enabled: enabled ?? t.enabled,
      );

  Future<void> _run(
    List<MealType> optimistic,
    Future<void> Function() save,
  ) async {
    setState(() => _items = optimistic);
    try {
      await save();
    } catch (e) {
      if (!mounted) return;
      setState(() => _items = null);
      snackFailure(context, e);
    }
  }

  Future<void> _update(
    List<MealType> items,
    MealType t, {
    String? name,
    double? weight,
    bool? enabled,
  }) => _run(
    [
      for (final x in items)
        x.id == t.id
            ? _with(x, name: name, weight: weight, enabled: enabled)
            : x,
    ],
    () => ref
        .read(mealControllerProvider)
        .updateMealType(t, name: name, weight: weight, enabled: enabled),
  );

  Future<String?> _askName(String title, [String initial = '']) {
    final l = AppLocalizations.of(context);
    final form = GlobalKey<FormState>();
    final controller = TextEditingController(text: initial);
    void submit(BuildContext context) {
      if (form.currentState!.validate()) {
        Navigator.pop(context, controller.text.trim());
      }
    }

    return AppSheet.show<String>(
      context,
      title: title,
      actions: [
        Builder(
          builder: (context) =>
              AppButton(label: l.save, onPressed: () => submit(context)),
        ),
      ],
      child: Form(
        key: form,
        child: Builder(
          builder: (context) => TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: l.mealTypesName,
              hintText: l.mealTypesNameHint,
            ),
            validator: (v) => (v ?? '').trim().isEmpty || v!.trim().length > 30
                ? l.mealTypesNameInvalid
                : null,
            onFieldSubmitted: (_) => submit(context),
          ),
        ),
      ),
    );
    // No dispose: the sheet's exit animation still builds the field after the
    // future completes, and a listener-free controller is simply collected.
  }

  Future<void> _add(String messId, List<MealType> items) async {
    final l = AppLocalizations.of(context);
    final name = await _askName(l.mealTypesAdd);
    if (name == null || !mounted) return;
    try {
      await ref
          .read(mealControllerProvider)
          .createMealType(messId, name: name, sortOrder: items.length);
    } catch (e) {
      if (mounted) snackFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messId = ref.watch(currentMessIdProvider);
    final manager = ref.watch(amIManagerProvider);

    final Widget body;
    List<MealType>? items;
    if (messId == null) {
      body = const LoadingView();
    } else if (!manager) {
      body = EmptyView(
        icon: Icons.lock_outline,
        message: l.mealTypesManagerOnly,
      );
    } else {
      // A fresh server list replaces the optimistic copy.
      ref.listen(mealTypesProvider(messId), (_, next) {
        if (next.hasValue && _items != null) setState(() => _items = null);
      });
      final async = ref.watch(mealTypesProvider(messId));
      items = _items ?? async.value;
      if (items == null && async.hasError) {
        body = ErrorView(
          message: failureText(context, async.error!),
          onRetry: () => ref.invalidate(mealTypesProvider(messId)),
        );
      } else if (items == null) {
        body = const LoadingView();
      } else if (items.isEmpty) {
        body = EmptyView(
          icon: Icons.restaurant_outlined,
          message: l.mealTypesEmpty,
        );
      } else {
        body = _list(items, messId);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.mealTypesTitle)),
      body: body,
      bottomNavigationBar: items == null || messId == null
          ? null
          : BottomAction(
              children: [
                AppButton(
                  label: l.mealTypesAdd,
                  icon: Icons.add,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _add(messId, items!),
                ),
              ],
            ),
    );
  }

  Widget _list(List<MealType> items, String messId) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final bn = bnDigits(context);
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.lg,
        ),
        child: Text(l.mealTypesHelp, style: text.bodyMedium),
      ),
      itemCount: items.length,
      onReorder: (from, to) {
        if (to > from) to -= 1;
        final next = [...items];
        next.insert(to, next.removeAt(from));
        _run(
          next,
          () => ref.read(mealControllerProvider).reorderMealTypes(messId, next),
        );
      },
      itemBuilder: (context, i) {
        final t = items[i];
        return DecoratedBox(
          key: ValueKey(t.id),
          decoration: BoxDecoration(
            color: p.bg,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              right: AppSpace.sm,
              top: AppSpace.xs,
              bottom: AppSpace.xs,
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: i,
                  child: const SizedBox.square(
                    dimension: AppSize.touch,
                    child: Icon(Icons.drag_indicator),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: () async {
                          final name = await _askName(
                            l.mealTypesRename,
                            t.name,
                          );
                          if (name != null && name != t.name && mounted) {
                            await _update(items, t, name: name);
                          }
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppSize.touch,
                          ),
                          child: Row(
                            spacing: AppSpace.sm,
                            children: [
                              Flexible(
                                child: Text(
                                  t.name,
                                  style: text.titleSmall?.copyWith(
                                    color: t.enabled ? null : p.inkTertiary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.edit_outlined,
                                size: AppSpace.lg,
                                color: p.inkTertiary,
                                semanticLabel: l.mealTypesRename,
                              ),
                            ],
                          ),
                        ),
                      ),
                      CountStepper(
                        label: l.mealTypesWeight,
                        value: '×${decimal(t.weight, bangla: bn)}',
                        onMinus: t.weight <= 0
                            ? null
                            : () => _update(items, t, weight: t.weight - 0.25),
                        onPlus: t.weight >= 5
                            ? null
                            : () => _update(items, t, weight: t.weight + 0.25),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: l.mealTypesEnabled(t.name),
                  child: Switch(
                    value: t.enabled,
                    onChanged: (v) => _update(items, t, enabled: v),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
