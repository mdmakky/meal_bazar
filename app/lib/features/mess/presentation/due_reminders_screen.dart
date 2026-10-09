import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/ids.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../money/domain/money.dart' show parseAmount;
import '../application/mess_providers.dart';
import '../domain/mess.dart';
import 'common.dart';

const _frequencies = [1, 2, 3, 7];

/// A text with sample values, as a member would read it.
String _filled(AppLocalizations l, String body, String mess) => body
    .replaceAll('{name}', l.dueRemSampleName)
    .replaceAll('{amount}', l.dueRemSampleAmount)
    .replaceAll('{mess}', mess);

/// Manager: automatic due reminders — on/off, how often, the minimum due
/// and the texts (supabase 0030). The cron sends them; nothing is sent here.
class DueRemindersScreen extends ConsumerStatefulWidget {
  const DueRemindersScreen({super.key});

  @override
  ConsumerState<DueRemindersScreen> createState() => _DueRemindersState();
}

class _DueRemindersState extends ConsumerState<DueRemindersScreen> {
  final _min = TextEditingController();
  String? _loadedFor;
  var _on = false;
  var _every = 3;
  var _savedMin = 0.0;

  @override
  void dispose() {
    _min.dispose();
    super.dispose();
  }

  Future<void> _save(String messId) async {
    final min = parseAmount(_min.text) ?? 0;
    try {
      await ref
          .read(messControllerProvider)
          .setDueReminders(messId, every: _on ? _every : null, min: min);
      _savedMin = min;
    } catch (e) {
      if (!mounted) return;
      // Back to what the server has.
      setState(() => _loadedFor = null);
      showFailure(context, e);
    }
  }

  void _saveMinIfChanged(String messId) {
    if ((parseAmount(_min.text) ?? 0) != _savedMin) _save(messId);
  }

  Future<void> _editText(Mess mess, [DueReminderText? existing]) async {
    final l = AppLocalizations.of(context);
    final body = await AppSheet.show<String>(
      context,
      title: existing == null ? l.dueRemAdd : l.dueRemEdit,
      child: _TextForm(messName: mess.name, initial: existing?.body),
    );
    if (body == null || !mounted) return;
    await _saveText(mess.id, (id: existing?.id ?? uuidV4(), body: body));
  }

  Future<void> _saveText(String messId, DueReminderText t) async {
    try {
      await ref.read(messControllerProvider).saveDueReminderText(messId, t);
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _delete(String messId, DueReminderText t) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.dueRemDeleteTitle,
      body: l.dueRemDeleteBody,
      action: l.delete,
    );
    if (!ok || !mounted) return;
    try {
      await ref
          .read(messControllerProvider)
          .deleteDueReminderText(messId, t.id);
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mess = ref.watch(currentMessProvider);
    final isManager = ref.watch(amIManagerProvider);

    if (mess != null && _loadedFor != mess.id) {
      _loadedFor = mess.id;
      _on = mess.dueReminderEvery != null;
      _every = mess.dueReminderEvery ?? 3;
      _savedMin = mess.dueReminderMin;
      _min.text = _savedMin == _savedMin.roundToDouble()
          ? '${_savedMin.toInt()}'
          : '$_savedMin';
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.dueRemTitle)),
      body: switch ((mess, isManager)) {
        (null, _) => const LoadingView(),
        (_, false) => EmptyView(
          message: l.settingsManagerOnly,
          icon: Icons.lock_outline,
        ),
        _ => _body(context, mess!),
      },
    );
  }

  Widget _body(BuildContext context, Mess mess) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final labels = {
      1: l.dueRemDaily,
      2: l.dueRemEvery2,
      3: l.dueRemEvery3,
      7: l.dueRemWeekly,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxxl,
      ),
      children: [
        Text(
          l.dueRemHelp,
          style: text.bodyMedium?.copyWith(color: p.inkSecondary),
        ),
        const SizedBox(height: AppSpace.lg),
        RaisedGroup(
          children: [
            SwitchListTile(
              key: const Key('dueRemSwitch'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
              ),
              title: Text(l.dueRemEnable, style: text.titleSmall),
              subtitle: Text(l.dueRemEnableSub),
              value: _on,
              onChanged: (v) {
                setState(() => _on = v);
                _save(mess.id);
              },
            ),
          ],
        ),
        if (_on) ...[
          const SizedBox(height: AppSpace.xl),
          Text(l.dueRemEvery, style: text.titleSmall),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              for (final d in _frequencies)
                ChoiceChip(
                  key: ValueKey('dueRemEvery-$d'),
                  label: Text(labels[d]!),
                  selected: _every == d,
                  onSelected: (_) {
                    setState(() => _every = d);
                    _save(mess.id);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          TextField(
            key: const Key('dueRemMin'),
            controller: _min,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9০-৯.]')),
            ],
            decoration: InputDecoration(
              labelText: l.dueRemMin,
              prefixText: '৳ ',
              helperText: l.dueRemMinHelp,
            ),
            onSubmitted: (_) => _saveMinIfChanged(mess.id),
            onTapOutside: (_) {
              FocusScope.of(context).unfocus();
              _saveMinIfChanged(mess.id);
            },
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        Row(
          children: [
            Expanded(child: Text(l.dueRemTexts, style: text.titleSmall)),
            TextButton.icon(
              key: const Key('dueRemAdd'),
              icon: const Icon(Icons.add),
              label: Text(l.dueRemAdd),
              onPressed: () => _editText(mess),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        _texts(context, mess),
      ],
    );
  }

  Widget _texts(BuildContext context, Mess mess) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final async = ref.watch(dueReminderTextsProvider(mess.id));
    return switch (async) {
      AsyncValue(:final value?) when value.isEmpty => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Text(
            l.dueRemTextsEmpty,
            style: text.bodyMedium?.copyWith(color: p.inkSecondary),
          ),
          RaisedGroup(
            inset: AppSpace.lg,
            children: [
              for (final (i, s) in [
                l.dueRemSuggest1('{name}', '{amount}'),
                l.dueRemSuggest2('{name}', '{amount}'),
                l.dueRemSuggest3('{name}', '{amount}'),
              ].indexed)
                ListTile(
                  key: ValueKey('dueRemSuggest-$i'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.xs,
                  ),
                  title: Text(_filled(l, s, mess.name), style: text.bodyMedium),
                  trailing: Icon(Icons.add_circle_outline, color: p.ink),
                  onTap: () => _saveText(mess.id, (id: uuidV4(), body: s)),
                ),
            ],
          ),
        ],
      ),
      AsyncValue(:final value?) => RaisedGroup(
        inset: AppSpace.lg,
        children: [
          for (final t in value)
            ListTile(
              contentPadding: const EdgeInsets.only(
                left: AppSpace.lg,
                right: AppSpace.xs,
              ),
              title: Text(t.body, style: text.bodyMedium),
              trailing: IconButton(
                tooltip: l.delete,
                icon: Icon(Icons.delete_outline, color: p.inkTertiary),
                onPressed: () => _delete(mess.id, t),
              ),
              onTap: () => _editText(mess, t),
            ),
        ],
      ),
      AsyncValue(:final error?) => ErrorView(
        message: failureText(context, error),
        onRetry: () => ref.invalidate(dueReminderTextsProvider(mess.id)),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(AppSpace.xl),
        child: LoadingView(),
      ),
    };
  }
}

/// Add / edit sheet body: the text, what the placeholders mean and a live
/// preview. Pops the trimmed text; the caller saves it.
class _TextForm extends StatefulWidget {
  const _TextForm({required this.messName, this.initial});

  final String messName;
  final String? initial;

  @override
  State<_TextForm> createState() => _TextFormState();
}

class _TextFormState extends State<_TextForm> {
  final _form = GlobalKey<FormState>();
  late final _body = TextEditingController(text: widget.initial);

  @override
  void initState() {
    super.initState();
    _body.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, _body.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final body = _body.text.trim();
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.lg,
        children: [
          TextFormField(
            key: const Key('dueRemText'),
            controller: _body,
            autofocus: widget.initial == null,
            minLines: 3,
            maxLines: 6,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: l.dueRemField,
              helperText: l.dueRemFieldHelp('{name}', '{amount}', '{mess}'),
              helperMaxLines: 3,
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? l.dueRemEmptyText : null,
          ),
          if (body.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.xs,
              children: [
                Text(
                  l.dueRemPreview,
                  style: text.labelMedium?.copyWith(color: p.inkTertiary),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Text(
                      _filled(l, body, widget.messName),
                      key: const Key('dueRemPreview'),
                      style: text.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          AppButton(label: l.save, expand: true, onPressed: _submit),
        ],
      ),
    );
  }
}
