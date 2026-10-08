import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors.dart';
import '../domain/profile.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  String? get currentUserId => _auth.currentUser?.id;

  /// Emits the signed-in user id (null when signed out), starting with the
  /// current session.
  Stream<String?> authStateChanges() =>
      _auth.onAuthStateChange.map((s) => s.session?.user.id);

  /// [phone] must already be E.164 (see `normalizeBdPhone`).
  Future<void> sendOtp(String phone) =>
      guard(() => _auth.signInWithOtp(phone: phone));

  Future<void> verifyOtp(String phone, String token) => guard(
    () => _auth.verifyOTP(phone: phone, token: token, type: OtpType.sms),
  );

  Future<void> signOut() => guard(() => _auth.signOut());

  Future<Profile> fetchMyProfile() => guard(() async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', _requireUserId())
        .single();
    return Profile.fromJson(row);
  });

  Future<Profile> updateProfile({String? fullName, String? locale}) =>
      guard(() async {
        final rows = await _client
            .from('profiles')
            .update({'full_name': ?fullName?.trim(), 'locale': ?locale})
            .eq('id', _requireUserId())
            .select();
        return Profile.fromJson(requireRows(rows).first);
      });

  String _requireUserId() =>
      currentUserId ?? (throw const AppFailure(FailureKind.notAuthenticated));
}
