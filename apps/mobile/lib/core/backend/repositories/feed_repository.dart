import 'package:mobile/core/utils/result.dart';

/// Contract for feed repository operations.
///
/// This interface defines the contract for post/feed data operations.
/// Network logic will be implemented in a future sprint.
///
/// Current behavior:
/// - Read/write locally.
/// - Backend sync will be added later.
///
/// TODO: Implement Supabase sync when backend is ready.
abstract class FeedRepository {
  /// Retrieves the feed for a user.
  ///
  /// TODO: Fetch from Supabase `posts` table with visibility filters.
  Future<Result<List<Map<String, dynamic>>>> getFeed(String userId);

  /// Creates a new post.
  ///
  /// TODO: Insert into Supabase `posts` table and upload media to `posts` bucket.
  Future<Result<Map<String, dynamic>>> createPost(Map<String, dynamic> post);

  /// Deletes a post.
  ///
  /// TODO: Delete from Supabase `posts` table and associated media.
  Future<Result<void>> deletePost(String postId);

  /// Likes a post.
  ///
  /// TODO: Insert into Supabase `post_likes` table.
  Future<Result<void>> likePost(String postId, String userId);

  /// Unlikes a post.
  ///
  /// TODO: Delete from Supabase `post_likes` table.
  Future<Result<void>> unlikePost(String postId, String userId);

  /// Shares a post.
  ///
  /// TODO: Insert into Supabase `shares` table.
  Future<Result<void>> sharePost(String postId, String userId);
}
