import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/gen/app_localizations.dart';
import 'core/platform/platform_config.dart';
import 'core/platform/platform_widgets.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/launch_intro.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/push/application/push_service.dart';
import 'features/reminders/application/reminder_service.dart';

class MealBazarApp extends ConsumerWidget {
  const MealBazarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reminderSyncProvider);
    ref.watch(pushSyncProvider);
    final locale = ref.watch(myProfileProvider.select((p) => p.value?.locale));
    final accentLight = ref.watch(
      platformConfigProvider.select((c) => c.accentLight),
    );
    final accentDark = ref.watch(
      platformConfigProvider.select((c) => c.accentDark),
    );
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      theme: AppTheme.light(accent: accentLight),
      darkTheme: AppTheme.dark(accent: accentDark),
      builder: (_, child) => LaunchIntro(
        ready: router.routerDelegate,
        isReady: () =>
            router.routerDelegate.currentConfiguration.uri.path != '/',
        child: PlatformGate(child: child ?? const SizedBox()),
      ),
      // Light only for now; dark mode returns with ThemeMode.system.
      themeMode: ThemeMode.light,
      locale: Locale(locale ?? 'bn'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
