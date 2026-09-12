import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/backend/supabase_client.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:mobile/core/utils/result.dart';

/// Repository for managing follow relationships between users.
///
/// Uses Supabase `followers` table when available.
/// Falls back to local persistence when Supabase is unavailable.
class FollowRepository {
  static const String _followsKey = 'follows';

  /// Follows a user.
  Future<Result<void>> followUser(String followerId, String followedId) async {
    // Try Supabase first
    if (SupabaseClientProvider.isInitialized) {
      try {
        await SupabaseClientProvider.client!.from('followers').insert({
          'follower_id': followerId,
          'following_id': followedId,
        });
        return Result.success(null);
      } catch (e, stack) {
        Logger.error(
          'Failed to follow user in Supabase. Falling back to local.',
          error: e,
          stackTrace: stack,
          tag: 'FollowRepository',
        );
      }
    }

    // Local fallback
    return _followLocal(followerId, followedId);
  }

  /// Unfollows a user.
  Future<Result<void>> unfollowUser(String followerId, String followedId) async {
    // Try Supabase first
    if (SupabaseClientProvider.isInitialized) {
      try {
        await SupabaseClientProvider.client!
            .from('followers')
            .delete()
            .eq('follower_id', followerId)
            .eq('following_id', followedId);
        return Result.success(null);
      } catch (e, stack) {
        Logger.error(
          'Failed to unfollow user in Supabase. Falling back to local.',
          error: e,
          stackTrace: stack,
          tag: 'FollowRepository',
        );
      }
    }

    // Local fallback
    return _unfollowLocal(followerId, followedId);
  }

  /// Checks if a user is following another user.
  Future<Result<bool>> isFollowing(String followerId, String followedId) async {
    // Try Supabase first
    if (SupabaseClientProvider.isInitialized && followerId.isNotEmpty) {
      try {
        final response = await SupabaseClientProvider.client!
            .from('followers')
            .select('follower_id')
            .eq('follower_id', followerId)
            .eq('following_id', followedId)
            .maybeSingle();
        return Result.success(response != null);
      } catch (e, stack) {
        Logger.error(
          'Failed to check follow status in Supabase. Falling back to local.',
          error: e,
          stackTrace: stack,
          tag: 'FollowRepository',
        );
      }
    }

    // Local fallback
    return _isFollowingLocal(followerId, followedId);
  }

  /// Gets the number of followers for a user.
  Future<Result<int>> followersCount(String userId) async {
    // Try Supabase first
    if (SupabaseClientProvider.isInitialized) {
      try {
        final response = await SupabaseClientProvider.client!
            .from('followers')
            .select('follower_id')
            .eq('following_id', userId);
        return Result.success(response.length);
      } catch (e, stack) {
        Logger.error(
          'Failed to get followers count in Supabase. Falling back to local.',
          error: e,
          stackTrace: stack,
          tag: 'FollowRepository',
        );
      }
    }

    // Local fallback
    return _followersCountLocal(userId);
  }

  /// Gets the number of users a user is following.
  Future<Result<int>> followingCount(String userId) async {
    // Try Supabase first
    if (SupabaseClientProvider.isInitialized) {
      try {
        final response = await SupabaseClientProvider.client!
            .from('followers')
            .select('following_id')
            .eq('follower_id', userId);
        return Result.success(response.length);
      } catch (e, stack) {
        Logger.error(
          'Failed to get following count in Supabase. Falling back to local.',
          error: e,
          stackTrace: stack,
          tag: 'FollowRepository',
        );
      }
    }

    // Local fallback
    return _followingCountLocal(userId);
  }

  /// Gets all followers of a user.
  Future<Result<List<String>>> getFollowers(String userId) async {
    // Try Supabase first
    if (SupabaseClientProvider.isInitialized) {
      try {
        final response = await SupabaseClientProvider.client!
            .from('followers')
            .select('follower_id')
            .eq('following_id', userId);
        return Result.success(
          response.map((r) => r['follower_id'] as String).toList(),
        );
      } catch (e, stack) {
        Logger.error(
          'Failed to get followers in Supabase. Falling back to local.',
          error: e,
          stackTrace: stack,
          tag: 'FollowRepository',
        );
      }
    }

    // Local fallback
    return _getFollowersLocal(userId);
  }

  /// Gets all users that a user is following.
  Future<Result<List<String>>> getFollowing(String userId) async {
    // Try Supabase first
    if (SupabaseClientProvider.isInitialized) {
      try {
        final response = await SupabaseClientProvider.client!
            .from('followers')
            .select('following_id')
            .eq('follower_id', userId);
        return Result.success(
          response.map((r) => r['following_id'] as String).toList(),
        );
      } catch (e, stack) {
        Logger.error(
          'Failed to get following in Supabase. Falling back to local.',
          error: e,
          stackTrace: stack,
          tag: 'FollowRepository',
        );
      }
    }

    // Local fallback
    return _getFollowingLocal(userId);
  }

  // --- Local persistence fallbacks (offline-safe) ---

  Future<Result<void>> _followLocal(String followerId, String followedId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followsString = prefs.getString(_followsKey);

      Map<String, List<String>> followsMap = {};
      if (followsString != null) {
        followsMap = Map<String, List<String>>.from(jsonDecode(followsString));
      }

      final key = '$followerId->$followedId';
      if (!followsMap.containsKey(key)) {
        followsMap[key] = [followerId, followedId];
        await prefs.setString(_followsKey, jsonEncode(followsMap));
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure('Failed to follow user: $e'));
    }
  }

  Future<Result<void>> _unfollowLocal(String followerId, String followedId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followsString = prefs.getString(_followsKey);

      if (followsString == null) {
        return Result.success(null);
      }

      Map<String, dynamic> followsMap = jsonDecode(followsString);
      final key = '$followerId->$followedId';
      followsMap.remove(key);

      await prefs.setString(_followsKey, jsonEncode(followsMap));

      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure('Failed to unfollow user: $e'));
    }
  }

  Future<Result<bool>> _isFollowingLocal(String followerId, String followedId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followsString = prefs.getString(_followsKey);

      if (followsString == null) {
        return Result.success(false);
      }

      Map<String, dynamic> followsMap = jsonDecode(followsString);
      final key = '$followerId->$followedId';

      return Result.success(followsMap.containsKey(key));
    } catch (e) {
      return Result.failure(Failure('Failed to check follow status: $e'));
    }
  }

  Future<Result<int>> _followersCountLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followsString = prefs.getString(_followsKey);

      if (followsString == null) {
        return Result.success(0);
      }

      Map<String, dynamic> followsMap = jsonDecode(followsString);
      int count = 0;

      for (final entry in followsMap.entries) {
        final parts = entry.key.split('->');
        if (parts.length == 2 && parts[1] == userId) {
          count++;
        }
      }

      return Result.success(count);
    } catch (e) {
      return Result.failure(Failure('Failed to get followers count: $e'));
    }
  }

  Future<Result<int>> _followingCountLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followsString = prefs.getString(_followsKey);

      if (followsString == null) {
        return Result.success(0);
      }

      Map<String, dynamic> followsMap = jsonDecode(followsString);
      int count = 0;

      for (final entry in followsMap.entries) {
        final parts = entry.key.split('->');
        if (parts.length == 2 && parts[0] == userId) {
          count++;
        }
      }

      return Result.success(count);
    } catch (e) {
      return Result.failure(Failure('Failed to get following count: $e'));
    }
  }

  Future<Result<List<String>>> _getFollowersLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followsString = prefs.getString(_followsKey);

      if (followsString == null) {
        return Result.success([]);
      }

      Map<String, dynamic> followsMap = jsonDecode(followsString);
      final followers = <String>[];

      for (final entry in followsMap.entries) {
        final parts = entry.key.split('->');
        if (parts.length == 2 && parts[1] == userId) {
          followers.add(parts[0]);
        }
      }

      return Result.success(followers);
    } catch (e) {
      return Result.failure(Failure('Failed to get followers: $e'));
    }
  }

  Future<Result<List<String>>> _getFollowingLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followsString = prefs.getString(_followsKey);

      if (followsString == null) {
        return Result.success([]);
      }

      Map<String, dynamic> followsMap = jsonDecode(followsString);
      final following = <String>[];

      for (final entry in followsMap.entries) {
        final parts = entry.key.split('->');
        if (parts.length == 2 && parts[0] == userId) {
          following.add(parts[1]);
        }
      }

      return Result.success(following);
    } catch (e) {
      return Result.failure(Failure('Failed to get following: $e'));
    }
  }
}