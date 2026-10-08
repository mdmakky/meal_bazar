/// Compile-time config passed with `--dart-define`. Never put secrets here.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Vercel AI gateway base URL. Empty = AI features show "AI is off".
  static const aiGatewayUrl = String.fromEnvironment('AI_GATEWAY_URL');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
