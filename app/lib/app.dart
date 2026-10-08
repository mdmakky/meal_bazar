import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/gen/app_localizations.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/reminders/application/reminder_service.dart';

class MealBazarApp extends ConsumerWidget {
  const MealBazarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reminderSyncProvider);
    final locale = ref.watch(myProfileProvider.select((p) => p.value?.locale));
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: Locale(locale ?? 'bn'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
