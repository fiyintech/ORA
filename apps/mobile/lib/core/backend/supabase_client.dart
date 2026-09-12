import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile/core/backend/backend_config.dart';
import 'package:mobile/core/utils/logger.dart';

/// Provides access to the Supabase client.
///
/// Initializes Supabase if configured.
/// If not configured, returns null — the app continues
/// to function in offline-first mode using local storage only.
class SupabaseClientProvider {
  static SupabaseClient? _client;

  /// Initializes Supabase.
  ///
  /// Call this in main() before runApp().
  /// If [BackendConfig.isConfigured] is false, Supabase is not initialized
  /// and the app runs in offline-only mode.
  static Future<void> initialize() async {
    if (!BackendConfig.isConfigured) {
      Logger.info(
        'Supabase not configured. Running in offline-only mode.',
        tag: 'Backend',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: BackendConfig.supabaseUrl!,
        publishableKey: BackendConfig.supabaseAnonKey!,
      );
      _client = Supabase.instance.client;
      Logger.info('Supabase initialized successfully.', tag: 'Backend');
    } catch (e, stack) {
      Logger.error(
        'Failed to initialize Supabase',
        error: e,
        stackTrace: stack,
        tag: 'Backend',
      );
      _client = null;
    }
  }

  /// Returns the Supabase client, or null if not initialized.
  static SupabaseClient? get client => _client;

  /// Whether Supabase is initialized and ready.
  static bool get isInitialized => _client != null;
}
