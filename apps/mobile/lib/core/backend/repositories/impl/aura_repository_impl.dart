import "package:mobile/core/utils/result.dart";
import "package:mobile/core/backend/repositories/aura_repository.dart";
import "package:mobile/core/backend/supabase_client.dart";
import "package:mobile/models/aura.dart";

class AuraRepositoryImpl implements AuraRepository {
  @override
  Future<Result<int>> getAuraPoints(String userId) async {
    // TODO: Implement Supabase query for profiles.aura_points
    // Expected: SELECT aura_points FROM profiles WHERE id = {userId}
    if (SupabaseClientProvider.isInitialized) {
      // TODO: Add Supabase query when backend is ready
      // final response = await SupabaseClientProvider.client
      //     .from('profiles')
      //     .select('aura_points')
      //     .eq('id', userId)
      //     .single();
      // return Result.success(response['aura_points'] as int);
    }
    return Result.success(0);
  }

  @override
  Future<Result<void>> recordAuraChange(String userId, int amount, String reason) async {
    // TODO: Implement Supabase insert into aura_history
    // Expected: INSERT INTO aura_history (user_id, amount, reason) VALUES ({userId}, {amount}, {reason})
    if (SupabaseClientProvider.isInitialized) {
      // TODO: Add Supabase query when backend is ready
    }
    return Result.success(null);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getAuraHistory(String userId) async {
    // TODO: Implement Supabase query for aura_history table
    // Expected: SELECT * FROM aura_history WHERE user_id = {userId} ORDER BY timestamp DESC
    if (SupabaseClientProvider.isInitialized) {
      // TODO: Add Supabase query when backend is ready
    }
    return Result.success(<Map<String, dynamic>>[]);
  }

  @override
  Future<Result<void>> awardAchievement(String userId, String achievementId) async {
    // TODO: Implement Supabase insert into user_achievements
    // Expected: INSERT INTO user_achievements (user_id, achievement_id) VALUES ({userId}, {achievementId})
    if (SupabaseClientProvider.isInitialized) {
      // TODO: Add Supabase query when backend is ready
    }
    return Result.success(null);
  }

  Future<List<Achievement>> getAchievements(String userId) async {
    // TODO: Replace with actual Supabase query with join
    // Expected: SELECT a.* FROM achievements a 
    //   JOIN user_achievements ua ON a.id = ua.achievement_id 
    //   WHERE ua.user_id = {userId}
    if (SupabaseClientProvider.isInitialized) {
      // TODO: Add Supabase query when backend is ready
    }
    // Fallback to mock data for offline mode
    await Future.delayed(const Duration(milliseconds: 300));
    return dummyAchievements;
  }

  Future<List<AuraHistoryEntry>> getMilestones(String userId) async {
    // TODO: Replace with actual Supabase query
    // Expected: SELECT * FROM aura_history WHERE user_id = {userId} AND action = 'milestone'
    if (SupabaseClientProvider.isInitialized) {
      // TODO: Add Supabase query when backend is ready
    }
    await Future.delayed(const Duration(milliseconds: 300));
    return dummyAuraHistory;
  }
}
