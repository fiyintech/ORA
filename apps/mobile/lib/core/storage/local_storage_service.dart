import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/models/user.dart';

/// Local storage for caching user data and preferences.
///
/// Authentication state is managed by Supabase Auth — this service is
/// used only for caching the user profile, preferences, drafts, and
/// theme. It never determines whether the user is logged in.
class LocalStorageService {
  static const String _userKey = 'user';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  /// Caches the user profile locally for offline access.
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Loads the cached user profile, or null if none exists.
  Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString == null) return null;

    try {
      final Map<String, dynamic> userMap = jsonDecode(userString);
      return User.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  /// Clears the cached user profile.
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Whether the first-run onboarding screens have been completed.
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Marks first-run onboarding as completed.
  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }
}
