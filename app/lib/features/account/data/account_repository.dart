import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors.dart';
import '../../../core/supabase.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(supabaseClientProvider)),
);

class AccountRepository {
  AccountRepository(this._client);

  final SupabaseClient _client;

  /// Anonymises my profile and leaves my messes (see 0007_account_deletion).
  /// Throws [AppFailure] (e.g. lastManager). The caller signs out afterwards.
  Future<void> deleteMyAccount() =>
      guard(() => _client.rpc<void>('delete_my_account'));
}
