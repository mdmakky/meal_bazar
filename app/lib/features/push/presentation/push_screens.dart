import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart';
import '../../money/presentation/money_sheets.dart' show banglaDigits;
import '../../reminders/application/reminder_service.dart';
import '../application/push_service.dart';
import '../domain/push.dart';

/// One switch per push type, saved to `profiles.notification_prefs`.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static (IconData, String, String) _copy(
    AppLocalizations l,
    PushType t,
  ) => switch (t) {
    PushType.joinRequest => (
      Icons.person_add_alt,
      l.pushJoinRequest,
      l.pushJoinRequestSub,
    ),
    PushType.depositPending => (
      Icons.hourglass_top,
      l.pushDepositPending,
      l.pushDepositPendingSub,
    ),
    PushType.depositVerified => (
      Icons.verified_outlined,
      l.pushDepositVerified,
      l.pushDepositVerifiedSub,
    ),
    PushType.depositRejected => (
      Icons.block,
      l.pushDepositRejected,
      l.pushDepositRejectedSub,
    ),
    PushType.notice => (Icons.campaign_outlined, l.pushNotice, l.pushNoticeSub),
    PushType.bazarAdded => (
      Icons.shopping_basket_outlined,
      l.pushBazar,
      l.pushBazarSub,
    ),
    PushType.expenseAdded => (
      Icons.receipt_long_outlined,
      l.pushExpense,
      l.pushExpenseSub,
    ),
    PushType.monthClosed => (
      Icons.event_available_outlined,
      l.pushMonthClosed,
      l.pushMonthClosedSub,
    ),
    PushType.dueReminder => (Icons.payments_outlined, l.pushDue, l.pushDueSub),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final prefs = ref.watch(notificationPrefsProvider);
    final permitted = ref.watch(notificationPermissionProvider).value ?? true;
    final isManager = ref.watch(amIManagerProvider);

    Future<void> set(PushType t, bool on) async {
      try {
        await ref.read(notificationPrefsProvider.notifier).set(t, on);
      } catch (e) {
        if (context.mounted) showFailure(context, e);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.pushTitle)),
      body: prefs.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: failureText(context, e),
          onRetry: () => ref.invalidate(notificationPrefsProvider),
        ),
        data: (p) => StaggeredList(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.gutter),
            children: StaggeredList.wrap([
              if (!permitted)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.lg),
                  child: AppCard.raised(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpace.sm,
                      children: [
                        Row(
                          spacing: AppSpace.md,
                          children: [
                            IconTile(
                              Icons.notifications_off_outlined,
                              color: context.palette.warning,
                            ),
                            Expanded(
                              child: Text(
                                l.remindPermissionOff,
                                style: text.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        Text(l.pushPermissionBody),
                        AppButton(
                          label: l.remindPermissionButton,
                          icon: Icons.notifications_active_outlined,
                          onPressed: () async {
                            await ref
                                .read(localNotificationsProvider)
                                .requestPermission();
                            ref.invalidate(notificationPermissionProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: Text(
                  l.pushIntro,
                  style: text.bodyMedium?.copyWith(
                    color: context.palette.inkSecondary,
                  ),
                ),
              ),
              RaisedGroup(
                children: [
                  for (final t in PushType.values)
                    if (isManager || !t.managerOnly)
                      _toggle(
                        context,
                        _copy(l, t),
                        value: p.isOn(t),
                        onChanged: (on) => set(t, on),
                      ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _toggle(
    BuildContext context,
    (IconData, String, String) copy, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final (icon, title, sub) = copy;
    return SwitchListTile(
      contentPadding: const EdgeInsets.only(
        left: AppSpace.lg,
        right: AppSpace.sm,
      ),
      secondary: IconTile(icon),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(sub),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Manager, Money tab: push each member who owes their due (after a confirm).
class SendDueRemindersButton extends ConsumerStatefulWidget {
  const SendDueRemindersButton({super.key, required this.messId});

  final String messId;

  @override
  ConsumerState<SendDueRemindersButton> createState() =>
      _SendDueRemindersButtonState();
}

class _SendDueRemindersButtonState
    extends ConsumerState<SendDueRemindersButton> {
  bool _sending = false;

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.dueRemindConfirmTitle,
      body: l.dueRemindConfirmBody,
      action: l.dueRemindSend,
    );
    if (!ok || !mounted) return;
    setState(() => _sending = true);
    try {
      final n = await ref
          .read(pushRepositoryProvider)
          .sendDueReminders(widget.messId);
      if (!mounted) return;
      showSnack(
        context,
        n == 0
            ? l.dueRemindNone
            : l.dueRemindSent(Fmt.digits('$n', bangla: banglaDigits(context))),
      );
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppButton(
    label: AppLocalizations.of(context).dueRemindButton,
    icon: Icons.notifications_active_outlined,
    variant: AppButtonVariant.secondary,
    loading: _sending,
    onPressed: _sending ? null : _send,
  );
}
