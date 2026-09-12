import 'package:mobile/core/utils/result.dart';

/// Contract for Hood repository operations.
///
/// This interface defines the contract for Hood/community data operations.
/// Network logic will be implemented in a future sprint.
///
/// Current behavior:
/// - Read/write locally.
/// - Backend sync will be added later.
///
/// TODO: Implement Supabase sync when backend is ready.
abstract class HoodRepository {
  /// Retrieves all Hoods.
  ///
  /// TODO: Fetch from Supabase `hoods` table.
  Future<Result<List<Map<String, dynamic>>>> getHoods();

  /// Retrieves a Hood by ID.
  ///
  /// TODO: Fetch from Supabase `hoods` table.
  Future<Result<Map<String, dynamic>?>> getHoodById(String hoodId);

  /// Creates a new Hood.
  ///
  /// TODO: Insert into Supabase `hoods` table.
  Future<Result<Map<String, dynamic>>> createHood(
    String ownerId,
    Map<String, dynamic> hoodData,
  );

  /// Joins a Hood.
  ///
  /// TODO: Insert into Supabase `hood_members` table.
  Future<Result<void>> joinHood(String hoodId, String userId);

  /// Leaves a Hood.
  ///
  /// TODO: Delete from Supabase `hood_members` table.
  Future<Result<void>> leaveHood(String hoodId, String userId);

  /// Retrieves members of a Hood.
  ///
  /// TODO: Fetch from Supabase `hood_members` table with `profiles` join.
  Future<Result<List<Map<String, dynamic>>>> getMembers(String hoodId);

  /// Retrieves posts for a Hood.
  ///
  /// TODO: Fetch from Supabase `hood_posts` table.
  Future<Result<List<Map<String, dynamic>>>> getHoodPosts(String hoodId);
}
