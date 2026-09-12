import 'package:mobile/core/models/user.dart';
import 'package:mobile/core/utils/result.dart';

/// Contract for user repository operations.
///
/// This interface defines the contract for user data operations.
/// Network logic will be implemented in a future sprint.
///
/// Current behavior:
/// - Read/write locally via LocalStorageService.
/// - Backend sync will be added later.
///
/// TODO: Implement Supabase sync when backend is ready.
abstract class UserRepository {
  /// Creates a new user.
  ///
  /// TODO: Sync to Supabase `users` and `profiles` tables.
  Future<Result<User>> create(User user);

  /// Retrieves a user by ID.
  ///
  /// TODO: Fetch from Supabase `profiles` table.
  Future<Result<User?>> getById(String id);

  /// Updates a user.
  ///
  /// TODO: Sync to Supabase `profiles` table.
  Future<Result<User>> update(User user);

  /// Deletes a user.
  ///
  /// TODO: Delete from Supabase `users` and `profiles` tables.
  Future<Result<void>> delete(String id);

  /// Searches users by username.
  ///
  /// TODO: Query Supabase `profiles` table with `username` filter.
  Future<Result<List<User>>> search(String query);
}
