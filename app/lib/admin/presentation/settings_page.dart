import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/widgets/widgets.dart';
import '../application/admin_providers.dart';
import '../domain/config_schema.dart';
import 'common.dart';
import 'config_editor.dart';

/// Features, App, Defaults, Bazar catalogue and Payment methods. AI and
/// Branding have their own pages.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final config = ref.watch(platformConfigAdminProvider);
    return config.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: adminErrorText(context, e),
        onRetry: () => ref.invalidate(platformConfigAdminProvider),
      ),
      data: (c) => AdminPage(
        title: l.adminNavSettings,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.xl,
          children: [
            FeaturesEditor(saved: c['features']),
            AppConfigEditor(saved: c['app']),
            DefaultsEditor(saved: c['defaults']),
            CatalogueEditor(saved: c['catalogue']),
            PaymentMethodsEditor(saved: c['payment_methods']),
          ],
        ),
      ),
    );
  }
}

// ── Field helpers: each writes straight into the draft map ───────────────

Widget textField(
  BuildContext context,
  Map m,
  String key,
  String label, {
  Invalid? Function(String?)? rule,
  int maxLines = 1,
  bool asInt = false,
  bool asDouble = false,
  String? helper,
}) => TextFormField(
  key: ValueKey(Object.hash(identityHashCode(m), key)),
  initialValue: '${m[key] ?? ''}',
  maxLines: maxLines,
  minLines: 1,
  decoration: InputDecoration(labelText: label, helperText: helper),
  validator: rule == null ? null : (v) => invalidText(context, rule(v)),
  onChanged: (v) => m[key] = asInt
      ? int.tryParse(v.trim()) ?? v
      : asDouble
      ? double.tryParse(v.trim()) ?? v
      : v,
);

Widget switchTile(
  Map m,
  String key,
  String title,
  VoidCallback changed, {
  String? subtitle,
}) => SwitchListTile(
  contentPadding: EdgeInsets.zero,
  title: Text(title),
  subtitle: subtitle == null ? null : Text(subtitle),
  value: m[key] == true,
  onChanged: (v) {
    m[key] = v;
    changed();
  },
);

/// Rows with move up / move down / remove, plus an Add button.
class ListEditor extends StatelessWidget {
  const ListEditor({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.newItem,
    required this.addLabel,
    required this.changed,
  });

  final List items;
  final Widget Function(Map item) itemBuilder;
  final Map<String, dynamic> Function() newItem;
  final String addLabel;
  final VoidCallback changed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    void move(int i, int to) {
      items.insert(to, items.removeAt(i));
      changed();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        for (var i = 0; i < items.length; i++)
          Row(
            key: ObjectKey(items[i]),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: itemBuilder(items[i] as Map)),
              IconButton(
                tooltip: l.adminMoveUp,
                icon: const Icon(Icons.arrow_upward),
                onPressed: i == 0 ? null : () => move(i, i - 1),
              ),
              IconButton(
                tooltip: l.adminMoveDown,
                icon: const Icon(Icons.arrow_downward),
                onPressed: i == items.length - 1 ? null : () => move(i, i + 1),
              ),
              IconButton(
                tooltip: l.delete,
                icon: const Icon(Icons.close),
                onPressed: () {
                  items.removeAt(i);
                  changed();
                },
              ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(addLabel),
            onPressed: () {
              items.add(newItem());
              changed();
            },
          ),
        ),
      ],
    );
  }
}

// ── Features ─────────────────────────────────────────────────────────────

class FeaturesEditor extends StatelessWidget {
  const FeaturesEditor({super.key, required this.saved});

  final Object? saved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bn = isBn(context);
    return ConfigKeyEditor(
      configKey: 'features',
      title: l.adminFeatures,
      subtitle: l.adminFeaturesHelp,
      saved: saved,
      builder: (context, draft, changed) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in featureGroups) ...[
            SubHeading(bn ? g.bn : g.en),
            for (final f in g.flags)
              switchTile(
                draft as Map,
                f.key,
                bn ? f.bn : f.en,
                changed,
                subtitle: f.key,
              ),
          ],
        ],
      ),
    );
  }
}

// ── App ──────────────────────────────────────────────────────────────────

class AppConfigEditor extends StatelessWidget {
  const AppConfigEditor({super.key, required this.saved});

  final Object? saved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ConfigKeyEditor(
      configKey: 'app',
      title: l.adminAppSection,
      saved: saved,
      builder: (context, d, changed) {
        final m = d as Map;
        final banner = m['banner'] as Map;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            switchTile(
              m,
              'maintenance',
              l.adminMaintenance,
              changed,
              subtitle: l.adminMaintenanceHelp,
            ),
            FieldRow(
              children: [
                textField(
                  context,
                  m,
                  'maintenance_message_bn',
                  l.adminMessageBn,
                  maxLines: 3,
                ),
                textField(
                  context,
                  m,
                  'maintenance_message_en',
                  l.adminMessageEn,
                  maxLines: 3,
                ),
              ],
            ),
            SubHeading(l.adminVersions),
            FieldRow(
              children: [
                textField(
                  context,
                  m,
                  'min_version',
                  l.adminMinVersion,
                  rule: version,
                  helper: l.adminMinVersionHelp,
                ),
                textField(
                  context,
                  m,
                  'latest_version',
                  l.adminLatestVersion,
                  rule: version,
                ),
              ],
            ),
            FieldRow(
              children: [
                textField(
                  context,
                  m,
                  'update_message_bn',
                  l.adminUpdateMessageBn,
                  maxLines: 3,
                ),
                textField(
                  context,
                  m,
                  'update_message_en',
                  l.adminUpdateMessageEn,
                  maxLines: 3,
                ),
              ],
            ),
            SubHeading(l.adminSupport),
            FieldRow(
              children: [
                textField(
                  context,
                  m,
                  'support_email',
                  l.adminSupportEmail,
                  rule: optionalEmail,
                ),
                textField(
                  context,
                  m,
                  'support_whatsapp',
                  l.adminSupportWhatsapp,
                ),
              ],
            ),
            textField(
              context,
              m,
              'privacy_url',
              l.adminPrivacyUrl,
              rule: optionalUrl,
            ),
            SubHeading(l.adminBanner),
            switchTile(banner, 'active', l.adminBannerActive, changed),
            FieldRow(
              children: [
                textField(
                  context,
                  banner,
                  'text_bn',
                  l.adminMessageBn,
                  maxLines: 3,
                ),
                textField(
                  context,
                  banner,
                  'text_en',
                  l.adminMessageEn,
                  maxLines: 3,
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: bannerLevels.contains(banner['level'])
                  ? banner['level'] as String
                  : 'info',
              decoration: InputDecoration(labelText: l.adminBannerLevel),
              items: [
                for (final v in bannerLevels)
                  DropdownMenuItem(value: v, child: Text(v)),
              ],
              onChanged: (v) {
                banner['level'] = v;
                changed();
              },
            ),
          ],
        );
      },
    );
  }
}

// ── Defaults ─────────────────────────────────────────────────────────────

class DefaultsEditor extends StatelessWidget {
  const DefaultsEditor({super.key, required this.saved});

  final Object? saved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ConfigKeyEditor(
      configKey: 'defaults',
      title: l.adminDefaults,
      subtitle: l.adminDefaultsHelp,
      saved: saved,
      validate: (context, d) => ((d as Map)['meal_types'] as List).isEmpty
          ? l.adminErrMealTypes
          : null,
      builder: (context, d, changed) {
        final m = d as Map;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            FieldRow(
              children: [
                textField(
                  context,
                  m,
                  'month_start_day',
                  l.adminMonthStartDay,
                  rule: (v) => intInRange(v, 1, 28),
                  asInt: true,
                ),
                textField(
                  context,
                  m,
                  'meal_off_cutoff',
                  l.adminCutoff,
                  rule: time,
                  helper: 'HH:MM',
                ),
              ],
            ),
            SubHeading(l.adminMealTypes),
            ListEditor(
              items: m['meal_types'] as List,
              addLabel: l.adminAdd,
              changed: changed,
              newItem: () => {'name': '', 'weight': 1, 'enabled': true},
              itemBuilder: (t) => Row(
                spacing: AppSpace.sm,
                children: [
                  Expanded(
                    flex: 3,
                    child: textField(
                      context,
                      t,
                      'name',
                      l.adminName,
                      rule: requiredText,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: textField(
                      context,
                      t,
                      'weight',
                      l.adminWeight,
                      rule: (v) => positiveNumber(v, max: 5),
                      asDouble: true,
                    ),
                  ),
                  Switch(
                    value: t['enabled'] != false,
                    onChanged: (v) {
                      t['enabled'] = v;
                      changed();
                    },
                  ),
                ],
              ),
            ),
            SubHeading(l.adminExpenseCategories),
            ListEditor(
              items: m['expense_categories'] as List,
              addLabel: l.adminAdd,
              changed: changed,
              newItem: () => {'name': '', 'split': 'equal'},
              itemBuilder: (c) => Row(
                spacing: AppSpace.sm,
                children: [
                  Expanded(
                    flex: 3,
                    child: textField(
                      context,
                      c,
                      'name',
                      l.adminName,
                      rule: requiredText,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: splitMethods.contains(c['split'])
                          ? c['split'] as String
                          : 'equal',
                      decoration: InputDecoration(labelText: l.adminSplit),
                      items: [
                        DropdownMenuItem(
                          value: 'equal',
                          child: Text(l.adminSplitEqual),
                        ),
                        DropdownMenuItem(
                          value: 'meal',
                          child: Text(l.adminSplitMeal),
                        ),
                      ],
                      onChanged: (v) {
                        c['split'] = v;
                        changed();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Bazar catalogue ──────────────────────────────────────────────────────

class CatalogueEditor extends StatelessWidget {
  const CatalogueEditor({super.key, required this.saved});

  final Object? saved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ConfigKeyEditor(
      configKey: 'catalogue',
      title: l.adminCatalogue,
      subtitle: l.adminCatalogueHelp,
      saved: saved,
      builder: (context, d, changed) => ListEditor(
        items: (d as Map)['groups'] as List,
        addLabel: l.adminAddGroup,
        changed: changed,
        newItem: () => {'name': '', 'items': <Object>[]},
        itemBuilder: (g) => Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            border: Border.all(color: context.palette.border),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.sm,
            children: [
              textField(
                context,
                g,
                'name',
                l.adminGroupName,
                rule: requiredText,
              ),
              Padding(
                padding: const EdgeInsets.only(left: AppSpace.lg),
                child: ListEditor(
                  items: (g['items'] ??= <Object>[]) as List,
                  addLabel: l.adminAddItem,
                  changed: changed,
                  newItem: () => {'name': '', 'unit': ''},
                  itemBuilder: (it) => Row(
                    spacing: AppSpace.sm,
                    children: [
                      Expanded(
                        flex: 3,
                        child: textField(
                          context,
                          it,
                          'name',
                          l.adminName,
                          rule: requiredText,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: textField(context, it, 'unit', l.adminUnit),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment methods ──────────────────────────────────────────────────────

class PaymentMethodsEditor extends StatelessWidget {
  const PaymentMethodsEditor({super.key, required this.saved});

  final Object? saved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ConfigKeyEditor(
      configKey: 'payment_methods',
      title: l.adminPaymentMethods,
      subtitle: l.adminPaymentMethodsHelp,
      saved: saved,
      builder: (context, d, changed) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          for (final m in (d as List).cast<Map>())
            Row(
              spacing: AppSpace.sm,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpace.md),
                    child: Text(
                      '${m['key']}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: textField(
                    context,
                    m,
                    'label_bn',
                    l.adminLabelBn,
                    rule: requiredText,
                  ),
                ),
                Expanded(
                  child: textField(
                    context,
                    m,
                    'label_en',
                    l.adminLabelEn,
                    rule: requiredText,
                  ),
                ),
                Switch(
                  value: m['enabled'] != false,
                  onChanged: (v) {
                    m['enabled'] = v;
                    changed();
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
