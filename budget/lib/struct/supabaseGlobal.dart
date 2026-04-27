import 'package:supabase_flutter/supabase_flutter.dart';

late SupabaseClient supabaseClient;

// SUPABASE_URL and SUPABASE_ANON_KEY are injected at build time via --dart-define:
//   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
//               --dart-define=SUPABASE_ANON_KEY=your-anon-key
const String _supabaseUrl =
    String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String _supabaseAnonKey =
    String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

Future<void> initSupabase() async {
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    print(
        'Supabase: SUPABASE_URL or SUPABASE_ANON_KEY not set — household sync disabled');
    return;
  }
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
    // OAuth 2.1 with PKCE is the default flow in supabase_flutter v2.
    // Ensure deep-link redirect is registered in AndroidManifest / Info.plist
    // using the scheme: io.supabase.cashew://login-callback
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  supabaseClient = Supabase.instance.client;
}

bool get isSupabaseConfigured => _supabaseUrl.isNotEmpty;

/// Sign in with an OAuth provider (Google, GitHub, etc.) using PKCE flow.
Future<void> signInWithOAuth(OAuthProvider provider) async {
  await supabaseClient.auth.signInWithOAuth(
    provider,
    redirectTo: 'io.supabase.cashew://login-callback',
  );
}

/// Sign in via magic-link (email OTP) — fallback when no OAuth provider is set up.
Future<void> signInWithMagicLink(String email) async {
  await supabaseClient.auth.signInWithOtp(
    email: email,
    emailRedirectTo: 'io.supabase.cashew://login-callback',
  );
}

Future<void> signOutSupabase() async {
  await supabaseClient.auth.signOut();
}

User? get currentSupabaseUser => supabaseClient.auth.currentUser;
