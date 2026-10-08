/// Compile-time config passed with `--dart-define`. Never put secrets here.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Vercel AI gateway base URL. Empty = AI features show "AI is off".
  static const aiGatewayUrl = String.fromEnvironment('AI_GATEWAY_URL');

  /// Google OAuth *web* client id (Supabase's Google provider uses the same
  /// one). Empty = the Google sign-in button is hidden.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
