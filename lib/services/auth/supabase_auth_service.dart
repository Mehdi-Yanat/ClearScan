import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  SupabaseAuthService._();

  static const _supabaseUrl = String.fromEnvironment('supabase_project_url');
  static const _googleServerClientId = String.fromEnvironment(
    'google_ID_client',
  );
  static const _supabasePublishableKey = String.fromEnvironment(
    'supabase_publishable_key',
  );

  static SupabaseClient? _client;
  static bool _googleSignInInitialized = false;
  static String? configurationError;
  static final ValueNotifier<User?> currentUser = ValueNotifier(null);

  static bool get isConfigured => _client != null;
  static bool get isGoogleSignInConfigured =>
      _client != null && _googleServerClientId.isNotEmpty;

  static Future<void> initialize() async {
    if (_supabaseUrl.isEmpty && _supabasePublishableKey.isEmpty) return;
    if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
      configurationError =
          'Both Supabase URL and publishable key are required.';
      return;
    }

    final uri = Uri.tryParse(_supabaseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      configurationError = 'The Supabase URL is invalid.';
      return;
    }

    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
    _client = Supabase.instance.client;
    currentUser.value = _client!.auth.currentUser;
    _client!.auth.onAuthStateChange.listen((data) {
      currentUser.value = data.session?.user;
    });
    if (_googleServerClientId.isNotEmpty) {
      await GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId,
      );
      _googleSignInInitialized = true;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _requireClient().auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return _requireClient().auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim()},
    );
  }

  static Future<AuthResponse> signInWithGoogle() async {
    final client = _requireClient();
    if (!_googleSignInInitialized) {
      throw Exception(
        'Google sign-in is not configured. Add the Google Web OAuth client ID '
        'as google_ID_client in .env, then restart the app with the Supabase '
        'launcher.',
      );
    }

    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception(
        'Google sign-in did not return an ID token. Check the Google OAuth '
        'client configuration.',
      );
    }

    return client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  static Future<void> signOut() async {
    await _requireClient().auth.signOut();
  }

  static SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw Exception(
        configurationError ?? 'Supabase authentication is not configured.',
      );
    }
    return client;
  }
}
