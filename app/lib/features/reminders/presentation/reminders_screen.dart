import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/failure_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/widgets/widgets.dart';
import '../../mess/application/mess_providers.dart';
import '../../mess/presentation/common.dart' show IconTile, NavRow, RaisedGroup;
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

    Widget toggle(ReminderKind k, IconData icon, String title, String sub) =>
        SwitchListTile(
          contentPadding: const EdgeInsets.only(
            left: AppSpace.lg,
            right: AppSpace.sm,
          ),
          secondary: IconTile(icon),
          title: Text(
            title,
            style: text.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(sub),
          value: settings.requireValue.of(k),
          onChanged: (on) =>
              ref.read(reminderSettingsProvider.notifier).set(k, on),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.remindTitle)),
      body: settings.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: failureText(context, e),
          onRetry: () => ref.invalidate(reminderSettingsProvider),
        ),
        data: (_) => StaggeredList(
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
              RaisedGroup(
                children: [
                  toggle(
                    ReminderKind.cutoff,
                    Icons.schedule,
                    l.remindCutoffToggle,
                    l.remindCutoffToggleSub,
                  ),
                  if (isManager)
                    toggle(
                      ReminderKind.nudge,
                      Icons.campaign_outlined,
                      l.remindNudgeToggle,
                      l.remindNudgeToggleSub,
                    ),
                  toggle(
                    ReminderKind.duty,
                    Icons.shopping_basket_outlined,
                    l.remindDutyToggle,
                    l.remindDutyToggleSub,
                  ),
                ],
              ),
              if (ref.featureOn('push'))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.lg),
                  child: RaisedGroup(
                    children: [
                      NavRow(
                        icon: Icons.notifications_active_outlined,
                        title: l.pushTitle,
                        subtitle: l.pushOpenSub,
                        onTap: () => context.push('/more/notifications'),
                      ),
                    ],
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
