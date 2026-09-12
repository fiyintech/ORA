import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/backend/supabase_client.dart';
import 'package:mobile/core/models/user.dart';
import 'package:mobile/core/storage/local_storage_service.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:mobile/features/auth/repository/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

enum AuthStatus { initial, authenticated, unauthenticated, loading }

/// Manages the user's authentication session.
///
/// Supabase Auth is the single source of truth for authentication state.
/// Local storage is used only for caching the user profile — never for
/// determining whether the user is logged in.
class SessionNotifier extends StateNotifier<AsyncValue<User?>> {
  final LocalStorageService _localStorageService;
  final AuthRepository _authRepository;
  StreamSubscription<AuthState>? _authSubscription;

  SessionNotifier(this._localStorageService, this._authRepository)
    : super(const AsyncValue.data(null)) {
    _initSession();
    _listenToAuthChanges();
  }

  /// Initializes the session by checking Supabase Auth first.
  ///
  /// If a valid Supabase session exists, restores the authenticated user.
  /// Otherwise, sets the session state to logged out.
  Future<void> _initSession() async {
    state = const AsyncValue.loading();

    try {
      if (SupabaseClientProvider.isInitialized) {
        final session = SupabaseClientProvider.client!.auth.currentSession;
        if (session != null) {
          final user = await _authRepository.getCurrentUser();
          state = AsyncValue.data(user);
          return;
        }
      }

      // Cached profiles are never treated as an authenticated session.
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to initialize session.',
        error: e,
        stackTrace: stackTrace,
        tag: 'Session',
      );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Listens to Supabase auth state changes and updates the session
  /// automatically.
  ///
  /// Handles:
  /// - `signedIn` — user signed in, restore user
  /// - `signedOut` — user signed out, clear session
  /// - `tokenRefreshed` — token refreshed, no state change needed
  /// - `userUpdated` — user profile updated, refresh user
  /// - `passwordRecovery` — password recovery requested, no state change
  void _listenToAuthChanges() {
    if (!SupabaseClientProvider.isInitialized) return;

    _authSubscription = SupabaseClientProvider.client!.auth.onAuthStateChange
        .listen((authState) async {
          final event = authState.event;

          switch (event) {
            case AuthChangeEvent.signedIn:
              final user = await _authRepository.getCurrentUser();
              state = AsyncValue.data(user);
              break;
            case AuthChangeEvent.signedOut:
              await _localStorageService.clearUser();
              state = const AsyncValue.data(null);
              break;
            case AuthChangeEvent.tokenRefreshed:
              // Token refreshed — no user state change needed.
              break;
            case AuthChangeEvent.userUpdated:
              final user = await _authRepository.getCurrentUser();
              state = AsyncValue.data(user);
              break;
            case AuthChangeEvent.passwordRecovery:
              // Password recovery requested — no session state change.
              break;
            default:
              break;
          }
        });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<User?> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = await _authRepository.register(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
      );

      if (user != null) {
        state = AsyncValue.data(user);
        // TODO: Emit UserLoggedInEvent when EventBus is accessible from StateNotifier
      } else {
        state = const AsyncValue.data(null);
      }

      return user;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> login({
    required String emailOrUsername,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = await _authRepository.login(
        emailOrUsername: emailOrUsername,
        password: password,
      );

      if (user != null) {
        state = AsyncValue.data(user);
        // TODO: Emit UserLoggedInEvent when EventBus is accessible from StateNotifier
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();

    try {
      await _authRepository.logout();
      state = const AsyncValue.data(null);
      // TODO: Emit UserLoggedOutEvent when EventBus is accessible from StateNotifier
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Resends the email verification link to the current user.
  Future<bool> resendVerification() async {
    return _authRepository.resendVerification();
  }

  /// Sends a password reset email to the given email address.
  Future<bool> sendPasswordReset(String email) async {
    return _authRepository.sendPasswordReset(email);
  }

  /// Updates the current user's password.
  Future<bool> updatePassword(String newPassword) async {
    return _authRepository.updatePassword(newPassword);
  }

  /// Updates the current user's email address.
  Future<bool> updateEmail(String newEmail) async {
    return _authRepository.updateEmail(newEmail);
  }

  /// Reauthenticates the current user with their password.
  Future<bool> reauthenticate(String password) async {
    return _authRepository.reauthenticate(password);
  }

  /// Refreshes the current user from the auth repository and updates
  /// both the session state and the local cache.
  ///
  /// Returns `true` if the refresh succeeded and a user is present.
  Future<bool> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
      if (user != null) {
        await _localStorageService.saveUser(user);
      }
      return user != null;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to refresh user.',
        error: e,
        stackTrace: stackTrace,
        tag: 'Session',
      );
      return false;
    }
  }
}

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);
  return AuthRepository(localStorageService);
});

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<User?>>((ref) {
      final localStorageService = ref.watch(localStorageServiceProvider);
      final authRepository = ref.watch(authRepositoryProvider);
      return SessionNotifier(localStorageService, authRepository);
    });

class OnboardingGateNotifier extends StateNotifier<AsyncValue<bool>> {
  final LocalStorageService _localStorageService;

  OnboardingGateNotifier(this._localStorageService)
    : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final completed = await _localStorageService.isOnboardingCompleted();
      state = AsyncValue.data(completed);
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to load onboarding state.',
        error: e,
        stackTrace: stackTrace,
        tag: 'Onboarding',
      );
      state = const AsyncValue.data(true);
    }
  }

  Future<void> complete() async {
    await _localStorageService.setOnboardingCompleted();
    state = const AsyncValue.data(true);
  }
}

final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingGateNotifier, AsyncValue<bool>>((ref) {
      final localStorageService = ref.watch(localStorageServiceProvider);
      return OnboardingGateNotifier(localStorageService);
    });

final currentUserProvider = Provider<User?>((ref) {
  final sessionState = ref.watch(sessionProvider);
  return sessionState.value;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
