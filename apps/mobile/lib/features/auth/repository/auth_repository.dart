import 'package:mobile/core/backend/supabase_client.dart';
import 'package:mobile/core/models/user.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// Authentication repository.
///
/// Uses Supabase Auth as the only authentication source.
/// Local storage caches the profile after a real sign-in; it is never used
/// to invent a session.
class AuthRepository {
  final LocalStorageService _localStorageService;

  AuthRepository(this._localStorageService);

  static const String _backendUnavailableMessage =
      'ORA backend is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY to .env.';

  /// Registers a new user with Supabase Auth.
  Future<User?> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    if (!SupabaseClientProvider.isInitialized) {
      throw Exception(_backendUnavailableMessage);
    }

    try {
      final client = SupabaseClientProvider.client!;

      // Sign up with Supabase Auth
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'full_name': fullName},
      );

      final authUser = response.user;
      if (authUser == null) {
        Logger.warning('Supabase sign-up returned no user.', tag: 'Auth');
        return null;
      }

      // Insert into profiles table (offline-safe — Supabase RLS will
      // typically auto-create the profile via a DB trigger, but we
      // upsert here to be explicit and safe).
      try {
        await _upsertProfile(
          userId: authUser.id,
          username: username,
          displayName: fullName,
          email: email,
        );
      } catch (profileError, profileStack) {
        Logger.error(
          'Failed to create profile after sign-up. Registration cannot continue.',
          error: profileError,
          stackTrace: profileStack,
          tag: 'Auth',
        );
        // Clients cannot delete Auth users. Sign out so a half-created
        // session is not treated as a completed registration.
        try {
          await client.auth.signOut();
        } catch (cleanupError) {
          Logger.error(
            'Failed to sign out after profile creation failure',
            error: cleanupError,
            tag: 'Auth',
          );
        }
        throw Exception(
          'Account was created but profile setup failed. Sign in with your email to finish setup.',
        );
      }

      // Build User object
      final user = User(
        id: authUser.id,
        fullName: fullName,
        username: username,
        email: email,
        auraPoints: 0,
        steezeLevel: 1,
        createdAt: _parseAuthUserDate(authUser.createdAt) ?? DateTime.now(),
      );

      // Cache locally for offline access
      await _localStorageService.saveUser(user);

      return user;
    } catch (e, stack) {
      Logger.error(
        'Supabase registration failed.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      rethrow;
    }
  }

  /// Logs in an existing user.
  ///
  /// Accepts either email or username. If username is provided (no @ symbol),
  /// looks up the email from the `profiles` table (written at signup).
  Future<User?> login({
    required String emailOrUsername,
    required String password,
  }) async {
    if (!SupabaseClientProvider.isInitialized) {
      throw Exception(_backendUnavailableMessage);
    }

    try {
      final client = SupabaseClientProvider.client!;

      // Determine if input is email or username
      final isEmail = emailOrUsername.contains('@');
      String? email = emailOrUsername;

      if (!isEmail) {
        // Look up email by username
        email = await _getEmailByUsername(emailOrUsername);
        if (email == null) {
          throw Exception('No account found with this username');
        }
      }

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final authUser = response.user;
      if (authUser == null) {
        return null;
      }

      // Fetch profile from Supabase
      final profile = await _fetchProfile(authUser.id);

      final user = User(
        id: authUser.id,
        fullName:
            profile?['display_name'] as String? ??
            authUser.userMetadata?['full_name'] as String? ??
            'User',
        username:
            profile?['username'] as String? ??
            authUser.userMetadata?['username'] as String? ??
            email.split('@').first,
        email: authUser.email ?? email,
        avatarUrl: profile?['avatar'] as String?,
        auraPoints: profile?['aura_points'] as int? ?? 0,
        steezeLevel: profile?['steeze_level'] as int? ?? 1,
        createdAt: _parseAuthUserDate(authUser.createdAt) ?? DateTime.now(),
      );

      // Cache locally for offline access
      await _localStorageService.saveUser(user);

      return user;
    } catch (e, stack) {
      Logger.error(
        'Supabase login failed.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      rethrow;
    }
  }

  /// Looks up a user's email by their username.
  Future<String?> _getEmailByUsername(String username) async {
    try {
      final client = SupabaseClientProvider.client;
      if (client == null) return null;

      final response = await client
          .from('profiles')
          .select('email')
          .eq('username', username)
          .maybeSingle();

      if (response == null) return null;

      final email = response['email'] as String?;
      if (email == null || email.isEmpty) return null;
      return email;
    } catch (e, stack) {
      Logger.error(
        'Failed to look up email by username.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      return null;
    }
  }

  /// Resends the email verification link to the current user.
  ///
  /// Returns `true` if the email was sent successfully.
  Future<bool> resendVerification() async {
    if (!SupabaseClientProvider.isInitialized) return false;

    try {
      final client = SupabaseClientProvider.client!;
      final user = client.auth.currentUser;
      if (user == null) return false;

      await client.auth.resend(type: OtpType.signup, email: user.email ?? '');
      return true;
    } catch (e, stack) {
      Logger.error(
        'Failed to resend verification email.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      rethrow;
    }
  }

  /// Sends a password reset email to the given email address.
  ///
  /// Returns `true` if the email was sent successfully.
  Future<bool> sendPasswordReset(String email) async {
    if (!SupabaseClientProvider.isInitialized) return false;

    try {
      final client = SupabaseClientProvider.client!;
      await client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e, stack) {
      Logger.error(
        'Failed to send password reset email.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      rethrow;
    }
  }

  /// Updates the current user's password.
  ///
  /// Requires an active session. Returns `true` on success.
  Future<bool> updatePassword(String newPassword) async {
    if (!SupabaseClientProvider.isInitialized) return false;

    try {
      final client = SupabaseClientProvider.client!;
      await client.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e, stack) {
      Logger.error(
        'Failed to update password.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      rethrow;
    }
  }

  /// Updates the current user's email address.
  ///
  /// Requires an active session. Returns `true` on success.
  Future<bool> updateEmail(String newEmail) async {
    if (!SupabaseClientProvider.isInitialized) return false;

    try {
      final client = SupabaseClientProvider.client!;
      await client.auth.updateUser(UserAttributes(email: newEmail));
      return true;
    } catch (e, stack) {
      Logger.error(
        'Failed to update email.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      rethrow;
    }
  }

  /// Reauthenticates the current user with their password.
  ///
  /// Required before sensitive operations like changing email.
  /// Returns `true` if reauthentication succeeded.
  Future<bool> reauthenticate(String password) async {
    if (!SupabaseClientProvider.isInitialized) return false;

    try {
      final client = SupabaseClientProvider.client!;
      final user = client.auth.currentUser;
      if (user == null) return false;

      await client.auth.reauthenticate();
      return true;
    } catch (e, stack) {
      Logger.error(
        'Failed to reauthenticate user.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      rethrow;
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    try {
      if (SupabaseClientProvider.isInitialized) {
        await SupabaseClientProvider.client!.auth.signOut();
      }
    } catch (e, stack) {
      Logger.error(
        'Supabase logout failed, clearing local.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
    }

    // Always clear local storage
    await _localStorageService.clearUser();
  }

  /// Gets the current authenticated user from the Supabase session only.
  Future<User?> getCurrentUser() async {
    if (!SupabaseClientProvider.isInitialized) {
      return null;
    }

    try {
      final session = SupabaseClientProvider.client!.auth.currentSession;
      final authUser = session?.user;

      if (authUser == null) {
        return null;
      }

      final profile = await _fetchProfile(authUser.id);

      final user = User(
        id: authUser.id,
        fullName:
            profile?['display_name'] as String? ??
            authUser.userMetadata?['full_name'] as String? ??
            'User',
        username:
            profile?['username'] as String? ??
            authUser.userMetadata?['username'] as String? ??
            authUser.email?.split('@').first ??
            'user',
        email: authUser.email ?? '',
        avatarUrl: profile?['avatar'] as String?,
        auraPoints: profile?['aura_points'] as int? ?? 0,
        steezeLevel: profile?['steeze_level'] as int? ?? 1,
        createdAt: _parseAuthUserDate(authUser.createdAt) ?? DateTime.now(),
      );

      await _localStorageService.saveUser(user);
      return user;
    } catch (e, stack) {
      Logger.error(
        'Supabase session check failed.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      return null;
    }
  }

  // --- Supabase helpers ---

  /// Parses the Supabase auth user's createdAt field.
  /// The field can be either a DateTime or a String depending on the API version.
  static DateTime? _parseAuthUserDate(Object? createdAt) {
    if (createdAt == null) return null;
    if (createdAt is DateTime) return createdAt.toLocal();
    if (createdAt is String) {
      return DateTime.tryParse(createdAt)?.toLocal();
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final client = SupabaseClientProvider.client;
      if (client == null) return null;

      final response = await client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e, stack) {
      Logger.error(
        'Failed to fetch profile from Supabase.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      return null;
    }
  }

  Future<void> _upsertProfile({
    required String userId,
    required String username,
    required String displayName,
    required String email,
  }) async {
    try {
      final client = SupabaseClientProvider.client;
      if (client == null) return;

      await client.from('profiles').upsert({
        'user_id': userId,
        'username': username,
        'display_name': displayName,
        'email': email,
        'aura_points': 0,
        'steeze_level': 1,
      }, onConflict: 'user_id');
    } catch (e, stack) {
      Logger.error(
        'Failed to upsert profile in Supabase.',
        error: e,
        stackTrace: stack,
        tag: 'Auth',
      );
      rethrow;
    }
  }
}
