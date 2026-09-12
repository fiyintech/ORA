import 'package:mobile/core/utils/result.dart';

/// Contract for Aura repository operations.
///
/// This interface defines the contract for Aura-related data operations.
/// Network logic will be implemented in a future sprint.
///
/// Current behavior:
/// - Read/write locally.
/// - Backend sync will be added later.
///
/// TODO: Implement Supabase sync when backend is ready.
abstract class AuraRepository {
  /// Retrieves the current Aura points for a user.
  ///
  /// TODO: Fetch from Supabase `profiles` table.
  Future<Result<int>> getAuraPoints(String userId);

  /// Records an Aura change.
  ///
  /// Every Aura change must be recorded in `aura_history`.
  ///
  /// TODO: Insert into Supabase `aura_history` table.
  /// TODO: Update `profiles.aura_points` with the new total.
  Future<Result<void>> recordAuraChange(
    String userId,
    int amount,
    String reason,
  );

  /// Retrieves the Aura history for a user.
  ///
  /// TODO: Fetch from Supabase `aura_history` table.
  Future<Result<List<Map<String, dynamic>>>> getAuraHistory(String userId);

  /// Awards an achievement to a user.
  ///
  /// TODO: Insert into Supabase `user_achievements` table.
  /// TODO: Trigger Aura award if the achievement has an Aura reward.
  Future<Result<void>> awardAchievement(String userId, String achievementId);
}
