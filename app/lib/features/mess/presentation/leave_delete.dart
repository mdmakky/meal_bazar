import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router.dart' show homePath;
import '../../../core/widgets/widgets.dart';
import '../../money/presentation/money_sheets.dart' show longDate, money;
import '../application/mess_providers.dart';
import '../domain/member.dart';
import 'common.dart';

/// More → "Leave this mess".
Future<void> showLeaveMessSheet(BuildContext context) => AppSheet.show<void>(
  context,
  title: AppLocalizations.of(context).leaveTitle,
  child: const LeaveMessForm(),
);

/// Mess settings → "Delete this mess" (owner).
Future<void> showDeleteMessSheet(BuildContext context) => AppSheet.show<void>(
  context,
  title: AppLocalizations.of(context).deleteMessTitle,
  child: const DeleteMessForm(),
);

/// What leaving means right now, then the one action that fits: leave at once
/// (settled or owed), ask the managers (owing), or hand over first (only manager).
class LeaveMessForm extends ConsumerStatefulWidget {
  const LeaveMessForm({super.key});

  @override
  ConsumerState<LeaveMessForm> createState() => _LeaveMessFormState();
}

class _LeaveMessFormState extends ConsumerState<LeaveMessForm> {
  late final String _messId = ref.read(currentMessIdProvider)!;
  late final _preview = ref.read(messControllerProvider).leavePreview(_messId);
  var _busy = false;

  Future<void> _run(
    Future<void> Function() action,
    String done, {
    bool leaves = false,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      final nav = Navigator.of(context);
      showSnack(context, done);
      nav.pop();
      if (leaves) context.go(homePath);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = ref.read(messControllerProvider);
    return FutureBuilder(
      future: _preview,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(failureText(context, snap.error!), style: text.bodyLarge);
        }
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AppSpace.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final p = snap.data;
        if (p == null) return Text(l.leaveNotMember, style: text.bodyLarge);
        final amount = money(context, p.balance.abs());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.lg,
          children: [
            Text(
              p.onlyManager
                  ? l.leaveOnlyManager
                  : p.balance < 0
                  ? l.leaveOwes(amount)
                  : p.balance > 0
                  ? l.leaveOwed(amount)
                  : l.leaveClean,
              key: const Key('leave-text'),
              style: text.bodyLarge,
            ),
            if (!p.onlyManager && p.balance < 0)
              AppButton(
                key: const Key('leave-ask'),
                label: l.leaveAsk,
                loading: _busy,
                onPressed: () =>
                    _run(() => c.requestLeave(_messId), l.leaveAsked),
              ),
            if (!p.onlyManager && p.balance >= 0)
              AppButton(
                key: const Key('leave-go'),
                label: l.leaveAction,
                variant: AppButtonVariant.secondary,
                loading: _busy,
                onPressed: () =>
                    _run(() => c.leaveMess(_messId), l.leaveDone, leaves: true),
              ),
          ],
        );
      },
    );
  }
}

/// The owner types the mess name to start the 30 days.
class DeleteMessForm extends ConsumerStatefulWidget {
  const DeleteMessForm({super.key});

  @override
  ConsumerState<DeleteMessForm> createState() => _DeleteMessFormState();
}

class _DeleteMessFormState extends ConsumerState<DeleteMessForm> {
  final _typed = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final mess = ref.watch(currentMessProvider)!;
    final matches = _typed.text.trim() == mess.name.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.lg,
      children: [
        Text(l.deleteMessBody, style: text.bodyLarge),
        AppButton(
          label: l.deleteMessBackup,
          icon: Icons.file_download_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/more/export');
          },
        ),
        TextField(
          key: const Key('delete-name'),
          controller: _typed,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l.deleteMessType(mess.name)),
        ),
        AppButton(
          key: const Key('delete-go'),
          label: l.deleteMessAction,
          loading: _busy,
          onPressed: !matches
              ? null
              : () async {
                  setState(() => _busy = true);
                  try {
                    await ref
                        .read(messControllerProvider)
                        .requestDeletion(mess.id, _typed.text);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    showSnack(context, l.deleteMessScheduled);
                  } catch (e) {
                    if (context.mounted) showFailure(context, e);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
        ),
      ],
    );
  }
}

/// Home, for everyone, while the mess is waiting to be erased; the owner can
/// call it off.
class DeletionBanner extends ConsumerWidget {
  const DeletionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mess = ref.watch(currentMessProvider);
    final on = mess?.deletesOn;
    if (mess == null || on == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final me = ref.watch(currentMembershipProvider)?.member;
    final owner =
        me != null &&
        me.role == MemberRole.manager &&
        (mess.createdBy == null || mess.createdBy == me.userId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        0,
      ),
      child: Container(
        key: const Key('deletion-banner'),
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: p.due.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.sm,
          children: [
            Row(
              spacing: AppSpace.sm,
              children: [
                Icon(Icons.delete_outline, color: p.due),
                Expanded(
                  child: Text(
                    l.deletionBanner(longDate(context, on)),
                    style: text.titleSmall?.copyWith(color: p.due),
                  ),
                ),
              ],
            ),
            if (owner)
              AppButton(
                key: const Key('deletion-cancel'),
                label: l.deleteMessCancel,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  try {
                    await ref
                        .read(messControllerProvider)
                        .cancelDeletion(mess.id);
                  } catch (e) {
                    if (context.mounted) showFailure(context, e);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
