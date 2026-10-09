import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/db.dart';
import '../core/env.dart';
import '../core/supabase.dart';
import 'presentation/admin_app.dart';

/// Super Admin web panel. Build:
/// `flutter build web -t lib/admin/admin_main.dart --dart-define-from-file=env.json`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.isConfigured) {
    runApp(const AdminConfigMissing());
    return;
  }
  await initSupabase();
  runApp(
    ProviderScope(
      overrides: [
        // The panel keeps no local copy; AuthRepository's DB stays unopened.
        appDbProvider.overrideWithValue(
          AppDb(
            LazyDatabase(
              () => throw UnsupportedError('No local DB in the admin panel'),
            ),
          ),
        ),
      ],
      child: const AdminApp(),
    ),
  );
}
