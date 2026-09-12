import 'package:mobile/core/utils/result.dart';

/// Contract for leaderboard repository operations.
///
/// This interface defines the contract for leaderboard data operations.
/// Network logic will be implemented in a future sprint.
///
/// Current behavior:
/// - Read/write locally.
/// - Backend sync will be added later.
///
/// TODO: Implement Supabase sync when backend is ready.
abstract class LeaderboardRepository {
  /// Retrieves the global leaderboard.
  ///
  /// TODO: Fetch from Supabase `leaderboard_cache` table.
  Future<Result<List<Map<String, dynamic>>>> getLeaderboard({
    int limit = 50,
    int offset = 0,
  });

  /// Retrieves a user's rank.
  ///
  /// TODO: Query Supabase `leaderboard_cache` table.
  Future<Result<int?>> getUserRank(String userId);

  /// Refreshes the leaderboard cache.
  ///
  /// TODO: Trigger Supabase Edge Function to recompute leaderboard.
  Future<Result<void>> refreshCache();
}
