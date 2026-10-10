import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/db.dart';
import '../../../core/env.dart';
import '../../../core/errors.dart';
import '../domain/profile.dart';

/// Where emailed auth links (confirm sign-up, reset password) land. Must be
/// listed under Supabase → Authentication → URL Configuration → Redirect URLs.
const authRedirectUrl = 'mealbazar://auth-callback';

class AuthRepository {
  AuthRepository(this._client, this._db, {this.beforeSignOut});

  final SupabaseClient _client;
  final AppDb _db;

  /// Runs while the session is still valid (removes this device's push
  /// token). Must not throw.
  final Future<void> Function()? beforeSignOut;

  GoTrueClient get _auth => _client.auth;

  String? get currentUserId => _auth.currentUser?.id;

  /// Emits the signed-in user id (null when signed out), starting with the
  /// current session.
  Stream<String?> authStateChanges() =>
      _auth.onAuthStateChange.map((s) => s.session?.user.id);

  /// Fires when a password-reset link opened the app. supabase_flutter
  /// exchanges the deep link for a session itself; the stream replays, so a
  /// late listener still sees it.
  Stream<void> passwordRecoveryEvents() => _auth.onAuthStateChange.where(
    (s) => s.event == AuthChangeEvent.passwordRecovery,
  );

  Future<void> signInWithEmail(String email, String password) => guard(
    () => _auth.signInWithPassword(email: email.trim(), password: password),
  );

  /// Returns false when the project requires email confirmation (no session
  /// yet): the user must click the emailed link, then log in.
  Future<bool> signUpWithEmail(String email, String password) => guard(
    () async =>
        (await _auth.signUp(
          email: email.trim(),
          password: password,
          emailRedirectTo: authRedirectUrl,
        )).session !=
        null,
  );

  /// PKCE: the link only works in the app install that requested it.
  Future<void> sendPasswordReset(String email) => guard(
    () =>
        _auth.resetPasswordForEmail(email.trim(), redirectTo: authRedirectUrl),
  );

  /// Signs in with the 6-10 digit code from the email ([OtpType.recovery] or
  /// [OtpType.signup]); a bad or expired code maps to `invalidOtp`.
  Future<void> verifyEmailOtp(String email, String token, OtpType type) =>
      guard(
        () => _auth.verifyOTP(email: email.trim(), token: token, type: type),
      );

  Future<void> resendSignupCode(String email) =>
      guard(() => _auth.resend(type: OtpType.signup, email: email.trim()));

  Future<void> updatePassword(String password) =>
      guard(() => _auth.updateUser(UserAttributes(password: password)));

  Future<void>? _googleInit;

  /// Native Google account picker, then a Supabase session from its ID token.
  /// Returns false when the user cancels.
  Future<bool> signInWithGoogle() => guard(() async {
    final google = GoogleSignIn.instance;
    await (_googleInit ??= google.initialize(
      serverClientId: Env.googleWebClientId,
    ));
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AppFailure(FailureKind.unknown, 'Google: no idToken');
    }
    // Supabase's Google provider accepts the ID token alone.
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
    return true;
  });

  // Phone OTP: unrouted until an SMS provider is funded (see router.dart).

  /// [phone] must already be E.164 (see `normalizeBdPhone`).
  Future<void> sendOtp(String phone) =>
      guard(() => _auth.signInWithOtp(phone: phone));

  Future<void> verifyOtp(String phone, String token) => guard(
    () => _auth.verifyOTP(phone: phone, token: token, type: OtpType.sms),
  );

  Future<void> signOut() async {
    await beforeSignOut?.call();
    return guard(() => _auth.signOut());
  }

  /// Cached, so an offline cold start still gets past the router; with
  /// [onStale], answered from the cache first (see [AppDb.cachedFirst]).
  Future<Profile> fetchMyProfile({void Function()? onStale}) => guard(() async {
    final uid = _requireUserId();
    Future<List<Map<String, dynamic>>> fetch() async => [
      await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .single()
          .retry(enabled: false),
    ];
    final key = 'profile:$uid';
    final rows = onStale == null
        ? await _db.cachedRows(key, fetch)
        : await _db.cachedFirst(key, fetch, onChanged: onStale);
    return Profile.fromJson(rows.single);
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
