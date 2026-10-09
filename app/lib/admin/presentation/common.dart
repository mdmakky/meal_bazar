import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/errors.dart';
import '../../core/failure_text.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../core/widgets/widgets.dart';
import '../domain/config_schema.dart';

bool isBn(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'bn';

String fmtDate(BuildContext context, DateTime? d) => d == null
    ? '—'
    : DateFormat.yMMMd(
        Localizations.localeOf(context).toString(),
      ).add_Hm().format(d.toLocal());

/// The localized text of a validation rule, for a TextFormField validator.
String? invalidText(BuildContext context, Invalid? i) {
  if (i == null) return null;
  final l = AppLocalizations.of(context);
  return switch (i) {
    Invalid.required => l.adminErrRequired,
    Invalid.number => l.adminErrNumber,
    Invalid.range => l.adminErrRange,
    Invalid.version => l.adminErrVersion,
    Invalid.email => l.adminErrEmail,
    Invalid.url => l.adminErrUrl,
    Invalid.time => l.adminErrTime,
    Invalid.hex => l.adminErrHex,
  };
}

/// The user-facing message plus the server's detail: admins need the SQL
/// error key (e.g. a config validation message) to fix their input.
String adminErrorText(BuildContext context, Object e) {
  final detail = mapError(e).debugMessage;
  final base = failureText(context, e);
  return detail == null || detail.isEmpty ? base : '$base\n$detail';
}

void showSnack(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

/// A page title row plus a body, with the standard gutter.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.scroll = true,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  /// False when [child] scrolls itself (tables with their own scroll view).
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.xl,
        AppSpace.xl,
        AppSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ...actions,
        ],
      ),
    );
    const pad = EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl);
    if (!scroll) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: Padding(padding: pad, child: child),
          ),
        ],
      );
    }
    return ListView(
      children: [
        header,
        Padding(padding: pad, child: child),
      ],
    );
  }
}

/// Asks for a reason (required when [requireReason]). Returns null on cancel.
Future<String?> askReason(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  bool requireReason = true,
}) {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(labelText: l.adminReason),
            validator: (v) =>
                requireReason ? invalidText(context, requiredText(v)) : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(width: 400, child: Text(body)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// A titled card that edits one platform_config key: Save (with the
/// error shown under it) and a read-only "Advanced: raw JSON" view.
class ConfigSection extends StatelessWidget {
  const ConfigSection({
    super.key,
    required this.title,
    required this.saved,
    required this.child,
    required this.onSave,
    required this.saving,
    this.error,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  /// The value as stored on the server, for the raw JSON view.
  final Object? saved;
  final Widget child;
  final VoidCallback? onSave;
  final bool saving;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Text(title, style: text.titleMedium),
          if (subtitle != null) Text(subtitle!, style: text.bodyMedium),
          child,
          if (error != null)
            Text(
              error!,
              style: text.bodyMedium?.copyWith(color: context.palette.due),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: l.save,
              icon: Icons.check,
              loading: saving,
              onPressed: onSave,
            ),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            title: Text(l.adminRawJson, style: text.labelMedium),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.md),
                color: context.palette.surfaceMuted,
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(saved),
                  style: text.bodyMedium?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A plain section heading inside a card.
class SubHeading extends StatelessWidget {
  const SubHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.md),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// Lays children in a row on wide cards and a column on narrow ones.
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => c.maxWidth >= 560
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.md,
            children: [for (final w in children) Expanded(child: w)],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: children,
          ),
  );
}
