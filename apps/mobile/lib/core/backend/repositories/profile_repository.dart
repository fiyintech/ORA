import 'package:mobile/core/utils/result.dart';

/// Contract for profile repository operations.
///
/// This interface defines the contract for profile data operations.
/// When Supabase is initialized, reads/writes go to the database.
/// When Supabase is unavailable, the app continues in offline mode.
abstract class ProfileRepository {
  /// Retrieves a profile by user ID.
  ///
  /// Reads from Supabase `profiles` table when available.
  Future<Result<Map<String, dynamic>?>> getProfile(String userId);

  /// Updates a profile.
  ///
  /// Writes to Supabase `profiles` table when available.
  /// Returns the updated profile row, or null if the profile was not found.
  Future<Result<Map<String, dynamic>?>> updateProfile(
    String userId,
    Map<String, dynamic> data,
  );

  /// Updates the profile completion percentage.
  ///
  /// Writes to Supabase `profiles` table when available.
  Future<Result<void>> updateCompletion(String userId, int percentage);

  /// Updates the avatar path.
  ///
  /// Uploads to Supabase storage bucket `avatars` when available.
  Future<Result<String>> updateAvatar(String userId, String imagePath);

  /// Updates the banner path.
  ///
  /// Uploads to Supabase storage bucket `banners` when available.
  Future<Result<String>> updateBanner(String userId, String imagePath);

  /// Validates a username for uniqueness and format.
  ///
  /// Returns `true` if the username is available.
  Future<Result<bool>> validateUsername(String username, {String? excludeUserId});

  /// Retrieves real profile statistics for a user.
  ///
  /// Queries Supabase for:
  /// - posts count
  /// - likes received
  /// - comments count
  /// - followers count
  /// - following count
  ///
  /// Returns all zeros when Supabase is unavailable (offline-safe).
  Future<Map<String, dynamic>> getProfileStats(String userId);

  /// Retrieves profile achievements for a user.
  Future<List<dynamic>> getAchievements(String userId);
}