import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/widgets/widgets.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import '../domain/config_schema.dart';
import 'common.dart';
import 'config_editor.dart';
import 'settings_page.dart' show switchTile, textField;

/// The catalogue loads every provider once; the provider tabs filter it.
final _catalogue = modelCatalogueProvider('all');

class AiPage extends ConsumerWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ref
        .watch(platformConfigAdminProvider)
        .when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: adminErrorText(context, e),
            onRetry: () => ref.invalidate(platformConfigAdminProvider),
          ),
          data: (c) => AdminPage(
            title: l.adminNavAi,
            child: AiSettingsEditor(saved: c['ai']),
          ),
        );
  }
}

class AiSettingsEditor extends ConsumerWidget {
  const AiSettingsEditor({super.key, required this.saved});

  final Object? saved;

  Future<bool> _confirmPaid(BuildContext context, WidgetRef ref, dynamic d) {
    final ai = d as Map;
    if (ai['allow_paid'] == true) return Future.value(true);
    final paid = paidChainEntries(ai, ref.read(_catalogue).value ?? const []);
    if (paid.isEmpty) return Future.value(true);
    final l = AppLocalizations.of(context);
    return confirmDialog(
      context,
      title: l.adminPaidWarningTitle,
      body: '${l.adminPaidWarningBody}\n\n${paid.join('\n')}',
      confirmLabel: l.adminSaveAnyway,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ConfigKeyEditor(
      configKey: 'ai',
      title: l.adminAiSettings,
      saved: saved,
      validate: (context, d) {
        for (final k in ['text_chain', 'vision_chain']) {
          final n = ((d as Map)[k] as List).length;
          if (n < 1 || n > maxChain) return l.adminErrChain;
        }
        return null;
      },
      beforeSave: (context, d) => _confirmPaid(context, ref, d),
      builder: (context, d, changed) {
        final m = d as Map;
        final chains = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.lg,
          children: [
            ChainEditor(
              title: l.adminTextChain,
              chain: m['text_chain'] as List,
              kind: 'text',
              changed: changed,
            ),
            ChainEditor(
              title: l.adminVisionChain,
              chain: m['vision_chain'] as List,
              kind: 'vision',
              changed: changed,
            ),
          ],
        );
        void add(ModelInfo model, String chainKey) {
          final chain = m[chainKey] as List;
          if (chain.length >= maxChain) {
            showSnack(context, l.adminErrChain);
            return;
          }
          chain.add({'provider': model.provider, 'model': model.id});
          changed();
        }

        final catalogue = ModelCatalogue(onAdd: add);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            switchTile(m, 'enabled', l.adminAiEnabled, changed),
            switchTile(
              m,
              'allow_paid',
              l.adminAllowPaid,
              changed,
              subtitle: l.adminAllowPaidHelp,
            ),
            FieldRow(
              children: [
                textField(
                  context,
                  m,
                  'quota_meal_draft',
                  l.adminQuotaMeal,
                  rule: (v) => intInRange(v, 0, 10000),
                  asInt: true,
                ),
                textField(
                  context,
                  m,
                  'quota_bazar_draft',
                  l.adminQuotaBazar,
                  rule: (v) => intInRange(v, 0, 10000),
                  asInt: true,
                ),
                textField(
                  context,
                  m,
                  'timeout_ms',
                  l.adminTimeoutMs,
                  rule: (v) => intInRange(v, 1000, 120000),
                  asInt: true,
                ),
              ],
            ),
            Row(
              children: [
                Text(l.adminTemperature),
                Expanded(
                  child: Slider(
                    value: ((m['temperature'] as num?)?.toDouble() ?? 0.2)
                        .clamp(0, 1),
                    divisions: 20,
                    label: '${m['temperature']}',
                    onChanged: (v) {
                      m['temperature'] = double.parse(v.toStringAsFixed(2));
                      changed();
                    },
                  ),
                ),
                Text('${m['temperature']}'),
              ],
            ),
            LayoutBuilder(
              builder: (context, c) => c.maxWidth >= 1000
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.xl,
                      children: [
                        Expanded(
                          flex: 3,
                          child: SizedBox(height: 640, child: catalogue),
                        ),
                        Expanded(flex: 2, child: chains),
                      ],
                    )
                  : DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          TabBar(
                            tabs: [
                              Tab(text: l.adminModelCatalogue),
                              Tab(text: l.adminChains),
                            ],
                          ),
                          SizedBox(
                            height: 640,
                            child: TabBarView(
                              children: [
                                catalogue,
                                SingleChildScrollView(child: chains),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Chains ───────────────────────────────────────────────────────────────

class ChainEditor extends ConsumerWidget {
  const ChainEditor({
    super.key,
    required this.title,
    required this.chain,
    required this.kind,
    required this.changed,
  });

  final String title;
  final List chain;
  final String kind;
  final VoidCallback changed;

  Future<void> _addManually(BuildContext context) async {
    final l = AppLocalizations.of(context);
    var provider = aiProviders.first;
    final model = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.adminAddManually),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpace.md,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: provider,
                  decoration: InputDecoration(labelText: l.adminProvider),
                  items: [
                    for (final p in aiProviders)
                      DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  onChanged: (v) => setState(() => provider = v!),
                ),
                TextField(
                  controller: model,
                  decoration: InputDecoration(labelText: l.adminModelId),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.adminAdd),
            ),
          ],
        ),
      ),
    );
    if (ok == true && model.text.trim().isNotEmpty) {
      chain.add({'provider': provider, 'model': model.text.trim()});
      changed();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final known = {
      for (final m in ref.watch(_catalogue).value ?? const <ModelInfo>[])
        '${m.provider}/${m.id}': m,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: text.titleSmall)),
            Text('${chain.length}/$maxChain', style: text.labelSmall),
          ],
        ),
        if (chain.isEmpty)
          Text(l.adminChainEmpty, style: text.bodyMedium)
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (from, to) {
              if (to > from) to -= 1;
              chain.insert(to, chain.removeAt(from));
              changed();
            },
            children: [
              for (var i = 0; i < chain.length; i++)
                _ChainEntry(
                  key: ObjectKey(chain[i]),
                  index: i,
                  entry: chain[i] as Map,
                  info: known['${chain[i]['provider']}/${chain[i]['model']}'],
                  kind: kind,
                  onRemove: () {
                    chain.removeAt(i);
                    changed();
                  },
                ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l.adminAddManually),
            onPressed: chain.length >= maxChain
                ? null
                : () => _addManually(context),
          ),
        ),
      ],
    );
  }
}

class _ChainEntry extends StatelessWidget {
  const _ChainEntry({
    super.key,
    required this.index,
    required this.entry,
    required this.info,
    required this.kind,
    required this.onRemove,
  });

  final int index;
  final Map entry;
  final ModelInfo? info;
  final String kind;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: AppSpace.sm,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Icon(Icons.drag_handle),
                ),
              ),
              Text('${index + 1}.', style: text.labelMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry['model']}', style: text.titleSmall),
                    Text('${entry['provider']}', style: text.labelSmall),
                  ],
                ),
              ),
              PriceBadge(info: info),
              IconButton(
                tooltip: l.delete,
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ],
          ),
          TestModelButton(
            provider: '${entry['provider']}',
            model: '${entry['model']}',
            kind: kind,
          ),
        ],
      ),
    );
  }
}

/// Free / Paid / unknown, monochrome: paid is the only colored one.
class PriceBadge extends StatelessWidget {
  const PriceBadge({super.key, required this.info});

  final ModelInfo? info;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final i = info;
    final (label, color) = i == null
        ? ('?', p.inkTertiary)
        : i.paid
        ? (l.adminPaid, p.warning)
        : (l.adminFree, p.inkSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Runs the gateway's test-model and shows latency + sample, or the error.
class TestModelButton extends ConsumerStatefulWidget {
  const TestModelButton({
    super.key,
    required this.provider,
    required this.model,
    required this.kind,
  });

  final String provider;
  final String model;
  final String kind;

  @override
  ConsumerState<TestModelButton> createState() => _TestModelButtonState();
}

class _TestModelButtonState extends ConsumerState<TestModelButton> {
  bool _busy = false;
  String? _result;
  bool _ok = true;

  Future<void> _test() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final r = await ref
          .read(adminRepositoryProvider)
          .testModel(widget.provider, widget.model, widget.kind);
      _ok = r.ok;
      _result = r.ok
          ? l.adminTestOk('${r.latencyMs}', r.sample)
          : (r.error ?? l.genericError);
    } on GatewayNotConfigured {
      _ok = false;
      _result = l.adminGatewayMissing;
    } catch (e) {
      _ok = false;
      if (mounted) _result = adminErrorText(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.palette;
    return Row(
      children: [
        TextButton(
          onPressed: _busy ? null : _test,
          child: _busy
              ? const SizedBox.square(
                  dimension: AppSize.spinner,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.adminTest),
        ),
        if (_result != null)
          Expanded(
            child: Text(
              _result!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: _ok ? p.advance : p.due),
            ),
          ),
      ],
    );
  }
}

// ── Catalogue ────────────────────────────────────────────────────────────

const _contextSteps = [0, 8000, 32000, 128000, 200000, 1000000];

class ModelCatalogue extends ConsumerStatefulWidget {
  const ModelCatalogue({super.key, required this.onAdd});

  /// Adds a model to `text_chain` or `vision_chain`.
  final void Function(ModelInfo model, String chainKey) onAdd;

  @override
  ConsumerState<ModelCatalogue> createState() => _ModelCatalogueState();
}

class _ModelCatalogueState extends ConsumerState<ModelCatalogue> {
  ModelFilter _f = defaultModelFilter;
  int _contextStep = 0;

  void _set(ModelFilter f) => setState(() => _f = f);

  ModelFilter _with({
    String? provider,
    String? search,
    bool? free,
    bool? paid,
    bool? vision,
    bool? text,
    int? minContext,
    double? maxPrice,
    bool clearMaxPrice = false,
    ModelSort? sort,
    bool? ascending,
  }) => (
    provider: provider ?? _f.provider,
    search: search ?? _f.search,
    free: free ?? _f.free,
    paid: paid ?? _f.paid,
    vision: vision ?? _f.vision,
    text: text ?? _f.text,
    minContext: minContext ?? _f.minContext,
    maxPrice: clearMaxPrice ? null : maxPrice ?? _f.maxPrice,
    sort: sort ?? _f.sort,
    ascending: ascending ?? _f.ascending,
  );

  DataColumn _col(String label, ModelSort sort, {bool numeric = false}) =>
      DataColumn(
        label: Text(label),
        numeric: numeric,
        onSort: (_, _) => _set(
          _with(sort: sort, ascending: _f.sort == sort ? !_f.ascending : true),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final models = ref.watch(_catalogue);
    String price(ModelInfo m, double? v) =>
        v == null ? '—' : (v == 0 ? l.adminFree : '\$${v.toStringAsFixed(2)}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l.adminModelCatalogue, style: text.titleSmall),
            ),
            IconButton(
              tooltip: l.retry,
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(_catalogue),
            ),
          ],
        ),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'all', label: Text(l.adminAll)),
            const ButtonSegment(value: 'gemini', label: Text('Gemini')),
            const ButtonSegment(value: 'openrouter', label: Text('OpenRouter')),
          ],
          selected: {_f.provider},
          onSelectionChanged: (s) => _set(_with(provider: s.first)),
        ),
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l.adminSearchModels,
          ),
          onChanged: (v) => _set(_with(search: v)),
        ),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: Text(l.adminFree),
              selected: _f.free,
              onSelected: (v) => _set(_with(free: v)),
            ),
            FilterChip(
              label: Text(l.adminPaid),
              selected: _f.paid,
              onSelected: (v) => _set(_with(paid: v)),
            ),
            FilterChip(
              label: Text(l.adminVision),
              selected: _f.vision,
              onSelected: (v) => _set(_with(vision: v)),
            ),
            FilterChip(
              label: Text(l.adminText),
              selected: _f.text,
              onSelected: (v) => _set(_with(text: v)),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l.adminMaxPrice,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) {
                  final n = double.tryParse(v.trim());
                  _set(_with(maxPrice: n, clearMaxPrice: n == null));
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(l.adminMinContext, style: text.labelMedium),
            Expanded(
              child: Slider(
                value: _contextStep.toDouble(),
                max: (_contextSteps.length - 1).toDouble(),
                divisions: _contextSteps.length - 1,
                label: _fmtContext(_contextSteps[_contextStep]),
                onChanged: (v) {
                  _contextStep = v.round();
                  _set(_with(minContext: _contextSteps[_contextStep]));
                },
              ),
            ),
            Text(_fmtContext(_contextSteps[_contextStep])),
          ],
        ),
        Expanded(
          child: models.when(
            loading: () => const LoadingView(),
            error: (e, _) => e is GatewayNotConfigured
                ? EmptyView(
                    message: l.adminGatewayMissing,
                    icon: Icons.cloud_off,
                  )
                : ErrorView(
                    message: adminErrorText(context, e),
                    onRetry: () => ref.invalidate(_catalogue),
                  ),
            data: (all) {
              final rows = filterModels(all, _f);
              if (rows.isEmpty) {
                return EmptyView(message: l.adminNoResults);
              }
              return SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    sortColumnIndex: _f.sort.index,
                    sortAscending: _f.ascending,
                    columns: [
                      _col(l.adminModel, ModelSort.name),
                      _col(l.adminProvider, ModelSort.provider),
                      _col(l.adminContext, ModelSort.context, numeric: true),
                      _col(
                        l.adminInputPrice,
                        ModelSort.inputPrice,
                        numeric: true,
                      ),
                      _col(
                        l.adminOutputPrice,
                        ModelSort.outputPrice,
                        numeric: true,
                      ),
                      DataColumn(label: Text(l.adminVision)),
                      const DataColumn(label: SizedBox.shrink()),
                    ],
                    rows: [
                      for (final m in rows)
                        DataRow(
                          cells: [
                            DataCell(
                              Tooltip(
                                message: m.description,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.label),
                                    Text(m.id, style: text.labelSmall),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(Text(m.provider)),
                            DataCell(Text(_fmtContext(m.contextLength))),
                            DataCell(Text(price(m, m.inputPrice))),
                            DataCell(Text(price(m, m.outputPrice))),
                            DataCell(
                              m.vision
                                  ? Icon(
                                      Icons.visibility_outlined,
                                      semanticLabel: l.adminVision,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: m.text
                                        ? () => widget.onAdd(m, 'text_chain')
                                        : null,
                                    child: Text(l.adminAddToText),
                                  ),
                                  TextButton(
                                    onPressed: m.vision
                                        ? () => widget.onAdd(m, 'vision_chain')
                                        : null,
                                    child: Text(l.adminAddToVision),
                                  ),
                                  SizedBox(
                                    width: 260,
                                    child: TestModelButton(
                                      provider: m.provider,
                                      model: m.id,
                                      kind: m.vision && !m.text
                                          ? 'vision'
                                          : 'text',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _fmtContext(int n) => n >= 1000000
    ? '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M'
    : n >= 1000
    ? '${n ~/ 1000}k'
    : '$n';
