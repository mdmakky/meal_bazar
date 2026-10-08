import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../application/reminder_service.dart';
import '../domain/reminders.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(reminderSettingsProvider);
    final permitted = ref.watch(notificationPermissionProvider).value ?? true;
    final isManager = ref.watch(amIManagerProvider);

    Widget toggle(ReminderKind k, String title, String sub) => SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      title: Text(title, style: text.titleSmall),
      subtitle: Text(sub),
      value: settings.requireValue.of(k),
      onChanged: (on) => ref.read(reminderSettingsProvider.notifier).set(k, on),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.remindTitle)),
      body: settings.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: failureText(context, e),
          onRetry: () => ref.invalidate(reminderSettingsProvider),
        ),
        data: (_) => ListView(
          children: [
            if (!permitted)
              Padding(
                padding: const EdgeInsets.all(AppSpace.gutter),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpace.sm,
                    children: [
                      Text(l.remindPermissionOff, style: text.titleSmall),
                      Text(l.remindPermissionBody),
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
            toggle(
              ReminderKind.cutoff,
              l.remindCutoffToggle,
              l.remindCutoffToggleSub,
            ),
            const Divider(),
            if (isManager) ...[
              toggle(
                ReminderKind.nudge,
                l.remindNudgeToggle,
                l.remindNudgeToggleSub,
              ),
              const Divider(),
            ],
            toggle(
              ReminderKind.duty,
              l.remindDutyToggle,
              l.remindDutyToggleSub,
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
