import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/supabase.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  if (!Env.isConfigured) {
    runApp(const ConfigMissingApp());
    return;
  }
  await initSupabase();
  runApp(const ProviderScope(child: MealBazarApp()));
}

/// Developer-facing: the build is missing its Supabase `--dart-define`s.
class ConfigMissingApp extends StatelessWidget {
  const ConfigMissingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('bn'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l = AppLocalizations.of(context);
          final text = Theme.of(context).textTheme;
          return Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.xxxl,
                  AppSpace.gutter,
                  AppSpace.gutter,
                ),
                children: [
                  Text(l.configMissingTitle, style: text.headlineSmall),
                  const SizedBox(height: AppSpace.md),
                  Text(l.configMissingBody, style: text.bodyLarge),
                  const SizedBox(height: AppSpace.lg),
                  const SelectableText(
                    'flutter run \\\n'
                    '  --dart-define=SUPABASE_URL=https://xyz.supabase.co \\\n'
                    '  --dart-define=SUPABASE_ANON_KEY=<anon key>',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
