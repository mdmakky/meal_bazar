import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/supabase.dart';
import '../../features/auth/application/auth_providers.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository.supabase(
    ref.watch(supabaseClientProvider),
    gatewayUrl: Env.aiGatewayUrl,
  ),
);

/// Signed-in user id. Unlike the app's `authStateProvider` this never
/// touches the local DB: the panel keeps no offline copy.
final adminSessionProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Null while signed out.
final isPlatformAdminProvider = FutureProvider<bool?>((ref) async {
  final uid = await ref.watch(adminSessionProvider.future);
  if (uid == null) return null;
  return ref.watch(adminRepositoryProvider).isPlatformAdmin();
});

final adminLocaleProvider = NotifierProvider<AdminLocale, Locale>(
  AdminLocale.new,
);

class AdminLocale extends Notifier<Locale> {
  @override
  Locale build() => const Locale('bn');

  void toggle() => state = Locale(state.languageCode == 'bn' ? 'en' : 'bn');
}

final adminStatsProvider = FutureProvider<AdminStats>(
  (ref) => ref.watch(adminRepositoryProvider).stats(),
);

final adminAiUsageProvider = FutureProvider<List<AiUsageRow>>(
  (ref) => ref.watch(adminRepositoryProvider).aiUsage(30),
);

final deletionQueueProvider = FutureProvider<List<DeletionRow>>(
  (ref) => ref.watch(adminRepositoryProvider).deletionQueue(),
);

final platformConfigAdminProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.watch(adminRepositoryProvider).config(),
);

final secretsProvider = FutureProvider<List<SecretRow>>(
  (ref) => ref.watch(adminRepositoryProvider).listSecrets(),
);

/// Model catalogue per provider tab (all, gemini, openrouter).
final modelCatalogueProvider = FutureProvider.family<List<ModelInfo>, String>(
  (ref, provider) => ref.watch(adminRepositoryProvider).models(provider),
);

typedef PageQuery = ({String search, int page});

const adminPageSize = 25;

final messesPageProvider = FutureProvider.family<List<MessRow>, PageQuery>(
  (ref, q) => ref
      .watch(adminRepositoryProvider)
      .listMesses(q.search, adminPageSize, q.page * adminPageSize),
);

final usersPageProvider = FutureProvider.family<List<UserRow>, PageQuery>(
  (ref, q) => ref
      .watch(adminRepositoryProvider)
      .listUsers(q.search, adminPageSize, q.page * adminPageSize),
);
