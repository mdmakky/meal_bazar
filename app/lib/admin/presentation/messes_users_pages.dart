import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/widgets/widgets.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import '../domain/config_schema.dart';
import 'common.dart';
import 'paged_table.dart';

/// Runs an admin write, then refreshes [refresh]; errors become a snackbar.
Future<void> runAdminAction(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action, {
  required ProviderOrFamily refresh,
}) async {
  final l = AppLocalizations.of(context);
  try {
    await action();
    if (context.mounted) showSnack(context, l.adminSaved);
  } catch (e) {
    if (context.mounted) showSnack(context, adminErrorText(context, e));
  } finally {
    ref.invalidate(refresh);
    ref.invalidate(adminStatsProvider);
  }
}

Widget _status(BuildContext context, DateTime? suspendedAt) {
  final l = AppLocalizations.of(context);
  final p = context.palette;
  return suspendedAt == null
      ? Text(l.adminActive)
      : Text(l.adminSuspended, style: TextStyle(color: p.due));
}

class MessesPage extends ConsumerWidget {
  const MessesPage({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, MessRow m) async {
    final l = AppLocalizations.of(context);
    final suspend = !m.suspended;
    final reason = await askReason(
      context,
      title: suspend
          ? l.adminSuspendMess(m.name)
          : l.adminUnsuspendMess(m.name),
      confirmLabel: suspend ? l.adminSuspend : l.adminUnsuspend,
      requireReason: suspend,
    );
    if (reason == null || !context.mounted) return;
    await runAdminAction(
      context,
      ref,
      () => ref
          .read(adminRepositoryProvider)
          .setMessSuspended(m.id, suspend, reason),
      refresh: messesPageProvider,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return PagedTable<MessRow>(
      title: l.adminNavMesses,
      searchHint: l.adminSearchMesses,
      emptyMessage: l.adminNoResults,
      load: messesPageProvider.call,
      columns: [
        l.adminName,
        l.adminMembers,
        l.adminManagers,
        l.adminCreated,
        l.adminLastActivity,
        l.adminStatus,
        '',
      ],
      cells: (context, m) => [
        Text(m.name),
        Text('${m.memberCount}'),
        Text(m.managerNames),
        Text(fmtDate(context, m.createdAt)),
        Text(fmtDate(context, m.lastActivity)),
        _status(context, m.suspendedAt),
        TextButton(
          onPressed: () => _toggle(context, ref, m),
          child: Text(m.suspended ? l.adminUnsuspend : l.adminSuspend),
        ),
      ],
    );
  }
}

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  Future<void> _toggleSuspend(
    BuildContext context,
    WidgetRef ref,
    UserRow u,
  ) async {
    final l = AppLocalizations.of(context);
    final suspend = !u.suspended;
    final reason = await askReason(
      context,
      title: suspend
          ? l.adminSuspendUser(u.email)
          : l.adminUnsuspendUser(u.email),
      confirmLabel: suspend ? l.adminSuspend : l.adminUnsuspend,
      requireReason: suspend,
    );
    if (reason == null || !context.mounted) return;
    await runAdminAction(
      context,
      ref,
      () => ref
          .read(adminRepositoryProvider)
          .setUserSuspended(u.id, suspend, reason),
      refresh: usersPageProvider,
    );
  }

  Future<void> _setAdmin(
    BuildContext context,
    WidgetRef ref,
    String email,
    bool isAdmin,
  ) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: isAdmin ? l.adminMakeAdmin : l.adminRemoveAdmin,
      body: email,
      confirmLabel: l.confirm,
    );
    if (!ok || !context.mounted) return;
    await runAdminAction(
      context,
      ref,
      () => ref.read(adminRepositoryProvider).setAdmin(email, isAdmin),
      refresh: usersPageProvider,
    );
  }

  Future<void> _addAdminByEmail(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    final form = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.adminMakeAdmin),
        content: SizedBox(
          width: 400,
          child: Form(
            key: form,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: l.signInEmailLabel),
              validator: (v) =>
                  invalidText(context, requiredText(v) ?? optionalEmail(v)),
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
            child: Text(l.adminMakeAdmin),
          ),
        ],
      ),
    );
    if (email == null || !context.mounted) return;
    await runAdminAction(
      context,
      ref,
      () => ref.read(adminRepositoryProvider).setAdmin(email, true),
      refresh: usersPageProvider,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return PagedTable<UserRow>(
      title: l.adminNavUsers,
      searchHint: l.adminSearchUsers,
      emptyMessage: l.adminNoResults,
      load: usersPageProvider.call,
      actions: [
        AppButton(
          label: l.adminMakeAdmin,
          icon: Icons.admin_panel_settings_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () => _addAdminByEmail(context, ref),
        ),
      ],
      columns: [
        l.signInEmailLabel,
        l.adminName,
        l.adminMessCount,
        l.adminCreated,
        l.adminLastSignIn,
        l.adminStatus,
        l.adminRole,
        '',
      ],
      cells: (context, u) => [
        Text(u.email),
        Text(u.fullName),
        Text('${u.messCount}'),
        Text(fmtDate(context, u.createdAt)),
        Text(fmtDate(context, u.lastSignInAt)),
        _status(context, u.suspendedAt),
        Text(u.isAdmin ? l.adminRoleAdmin : '—'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _toggleSuspend(context, ref, u),
              child: Text(u.suspended ? l.adminUnsuspend : l.adminSuspend),
            ),
            TextButton(
              onPressed: () => _setAdmin(context, ref, u.email, !u.isAdmin),
              child: Text(u.isAdmin ? l.adminRemoveAdmin : l.adminMakeAdmin),
            ),
          ],
        ),
      ],
    );
  }
}
