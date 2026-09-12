import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for the Supabase backend.
///
/// Reads credentials from a `.env` file.
/// Does not hardcode any credentials.
class BackendConfig {
  /// The Supabase project URL.
  static const String supabaseUrlEnvKey = 'SUPABASE_URL';

  /// The Supabase anonymous key.
  static const String supabaseAnonKeyEnvKey = 'SUPABASE_ANON_KEY';

  /// Initializes configuration from the `.env` file.
  ///
  /// Must be called once before reading config values.
  /// A missing `.env` is treated as "backend not configured".
  static Future<void> load() async {
    await dotenv.load(fileName: '.env', isOptional: true);
  }

  /// Returns the Supabase URL from the environment.
  /// Returns null if not configured.
  static String? get supabaseUrl {
    final value = dotenv.env[supabaseUrlEnvKey];
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Returns the Supabase anon key from the environment.
  /// Returns null if not configured.
  static String? get supabaseAnonKey {
    final value = dotenv.env[supabaseAnonKeyEnvKey];
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Whether the backend is configured (both URL and key are present).
  static bool get isConfigured =>
      supabaseUrl != null && supabaseAnonKey != null;
}
