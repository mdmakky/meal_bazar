import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/widgets/widgets.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import '../domain/config_schema.dart';
import 'common.dart';

/// Write-only platform credentials: shows name, ••••last4 and when it was
/// set. Stored values are never fetched, so they can't be displayed.
class CredentialsPage extends ConsumerWidget {
  const CredentialsPage({super.key});

  Future<void> _set(BuildContext context, WidgetRef ref, String name) async {
    final l = AppLocalizations.of(context);
    final value = await _askSecret(context, name);
    if (value == null || !context.mounted) return;
    await _run(context, ref, () async {
      await ref.read(adminRepositoryProvider).setSecret(name, value);
      if (context.mounted) showSnack(context, l.adminSaved);
    });
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String name) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.adminSecretDeleteTitle(name),
      body: l.adminSecretDeleteBody,
      confirmLabel: l.delete,
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(adminRepositoryProvider).setSecret(name, null),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) showSnack(context, adminErrorText(context, e));
    } finally {
      ref.invalidate(secretsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ref
        .watch(secretsProvider)
        .when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: adminErrorText(context, e),
            onRetry: () => ref.invalidate(secretsProvider),
          ),
          data: (rows) {
            final byName = {for (final r in rows) r.name: r};
            return AdminPage(
              title: l.adminNavCredentials,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.md,
                children: [
                  Text(l.adminSecretsHelp),
                  for (final name in secretNames)
                    _SecretTile(
                      name: name,
                      row: byName[name],
                      onSet: () => _set(context, ref, name),
                      onDelete: () => _delete(context, ref, name),
                    ),
                ],
              ),
            );
          },
        );
  }
}

class _SecretTile extends StatelessWidget {
  const _SecretTile({
    required this.name,
    required this.row,
    required this.onSet,
    required this.onDelete,
  });

  final String name;
  final SecretRow? row;
  final VoidCallback onSet;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final r = row;
    return AppCard(
      child: Row(
        spacing: AppSpace.md,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.xs,
              children: [
                Text(name, style: text.titleSmall),
                Text(
                  r == null
                      ? l.adminSecretNotSet
                      : '••••${r.last4}  ·  ${l.adminUpdatedAt(fmtDate(context, r.updatedAt))}',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          AppButton(
            label: r == null ? l.adminSecretSet : l.adminSecretReplace,
            variant: AppButtonVariant.secondary,
            onPressed: onSet,
          ),
          if (r != null)
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

/// Password-style entry; the value goes straight to the RPC.
Future<String?> _askSecret(BuildContext context, String name) {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(name),
      content: SizedBox(
        width: 400,
        child: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l.adminSecretValue,
              helperText: l.adminSecretValueHelp,
            ),
            validator: (v) => invalidText(context, requiredText(v)),
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
          child: Text(l.save),
        ),
      ],
    ),
  );
}
