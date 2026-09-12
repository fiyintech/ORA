import 'dart:io';

import "package:mobile/core/utils/result.dart";
import "package:mobile/core/backend/repositories/profile_repository.dart";
import "package:mobile/core/backend/supabase_client.dart";
import "package:mobile/core/utils/backend_error.dart";
import "package:mobile/core/utils/logger.dart";
import "package:supabase_flutter/supabase_flutter.dart";

class ProfileRepositoryImpl implements ProfileRepository {
  @override
  Future<Result<Map<String, dynamic>?>> getProfile(String userId) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(null);
    }

    try {
      final response = await SupabaseClientProvider.client!
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return Result.success(response);
    } catch (e, stack) {
      Logger.error(
        'Failed to fetch profile from Supabase.',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return Result.failure(backendFailure(e, stack));
    }
  }

  @override
  Future<Result<Map<String, dynamic>?>> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(null);
    }

    try {
      final updatedProfile = await SupabaseClientProvider.client!
          .from('profiles')
          .update(data)
          .eq('user_id', userId)
          .select()
          .maybeSingle();

      if (updatedProfile == null) {
        return Result.failure(const Failure('Profile not found.'));
      }

      return Result.success(updatedProfile);
    } on PostgrestException catch (e, stack) {
      logBackendError('updateProfile', e, stack, tag: 'ProfileRepository');
      return Result.failure(backendFailure(e, stack));
    } catch (e, stack) {
      logBackendError('updateProfile', e, stack, tag: 'ProfileRepository');
      return Result.failure(backendFailure(e, stack));
    }
  }

  @override
  Future<Result<void>> updateCompletion(String userId, int percentage) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(null);
    }

    try {
      await SupabaseClientProvider.client!
          .from('profiles')
          .update({'profile_completed': percentage})
          .eq('user_id', userId);
      return Result.success(null);
    } catch (e, stack) {
      Logger.error(
        'Failed to update profile completion.',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return Result.failure(Failure('Failed to update completion: $e'));
    }
  }

  @override
  Future<Result<String>> updateAvatar(String userId, String imagePath) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(imagePath);
    }

    try {
      final client = SupabaseClientProvider.client!;

      // Upload to Supabase storage bucket 'avatars'
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final storagePath = 'avatars/$userId/avatar.$ext';

      await client.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: ext == 'png'
                  ? 'image/png'
                  : ext == 'webp'
                  ? 'image/webp'
                  : 'image/jpeg',
            ),
          );

      final publicUrl = client.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      // Update profile with the public URL
      await client
          .from('profiles')
          .update({'avatar': publicUrl})
          .eq('user_id', userId);

      return Result.success(publicUrl);
    } on PostgrestException catch (e, stack) {
      Logger.error(
        '===== updateAvatar — PostgrestException =====\n'
        'Code: ${e.code}\n'
        'Message: ${e.message}\n'
        'Details: ${e.details}\n'
        'Hint: ${e.hint}',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return Result.failure(
        Failure(
          'Failed to update avatar: ${e.message} (code: ${e.code})'
          '${e.details != null ? '\nDetails: ${e.details}' : ''}'
          '${e.hint != null ? '\nHint: ${e.hint}' : ''}',
          error: e,
          stackTrace: stack,
        ),
      );
    } on StorageException catch (e, stack) {
      Logger.error(
        '===== updateAvatar — StorageException =====\n'
        'Message: ${e.message}\n'
        'Error: ${e.error}',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return Result.failure(Failure('Failed to upload avatar: ${e.message}'));
    } catch (e, stack) {
      Logger.error(
        '===== updateAvatar — Unknown Exception =====\n'
        'Exception type: ${e.runtimeType}\n'
        'Exception: $e\n'
        'Stack trace:\n$stack',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return Result.failure(Failure('Failed to update avatar: $e'));
    }
  }

  @override
  Future<Result<String>> updateBanner(String userId, String imagePath) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(imagePath);
    }

    try {
      final client = SupabaseClientProvider.client!;

      // Upload to Supabase storage bucket 'banners'
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final storagePath = 'banners/$userId/banner.$ext';

      await client.storage
          .from('banners')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: ext == 'png'
                  ? 'image/png'
                  : ext == 'webp'
                  ? 'image/webp'
                  : 'image/jpeg',
            ),
          );

      final publicUrl = client.storage
          .from('banners')
          .getPublicUrl(storagePath);

      // Update profile with the public URL
      await client
          .from('profiles')
          .update({'banner_url': publicUrl})
          .eq('user_id', userId);

      return Result.success(publicUrl);
    } on PostgrestException catch (e, stack) {
      Logger.error(
        '===== updateBanner — PostgrestException =====\n'
        'Code: ${e.code}\n'
        'Message: ${e.message}\n'
        'Details: ${e.details}\n'
        'Hint: ${e.hint}',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return Result.failure(
        Failure(
          'Failed to update banner: ${e.message} (code: ${e.code})'
          '${e.details != null ? '\nDetails: ${e.details}' : ''}'
          '${e.hint != null ? '\nHint: ${e.hint}' : ''}',
          error: e,
          stackTrace: stack,
        ),
      );
    } on StorageException catch (e, stack) {
      Logger.error(
        '===== updateBanner — StorageException =====\n'
        'Message: ${e.message}\n'
        'Error: ${e.error}',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return Result.failure(Failure('Failed to upload banner: ${e.message}'));
    } catch (e, stack) {
      Logger.error(
        '===== updateBanner — Unknown Exception =====\n'
        'Exception type: ${e.runtimeType}\n'
        'Exception: $e\n'
        'Stack trace:\n$stack',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return Result.failure(Failure('Failed to update banner: $e'));
    }
  }

  @override
  Future<Result<bool>> validateUsername(
    String username, {
    String? excludeUserId,
  }) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(true);
    }

    try {
      final client = SupabaseClientProvider.client!;

      var query = client
          .from('profiles')
          .select('user_id')
          .eq('username', username);

      if (excludeUserId != null) {
        query = query.neq('user_id', excludeUserId);
      }

      final response = await query.maybeSingle();
      return Result.success(response == null);
    } catch (e, stack) {
      Logger.error(
        'Failed to validate username.',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return Result.failure(Failure('Failed to validate username: $e'));
    }
  }

  @override
  Future<Map<String, dynamic>> getProfileStats(String userId) async {
    // Start with real values — never fake placeholder statistics.
    final stats = <String, dynamic>{
      'posts': 0,
      'likes': 0,
      'comments': 0,
      'hoods': 0,
      'followers': 0,
      'following': 0,
      'aura': 0,
      'username': '',
      'fullName': '',
    };

    if (!SupabaseClientProvider.isInitialized) {
      return stats;
    }

    try {
      final client = SupabaseClientProvider.client!;

      // Fetch profile info (username, fullName, aura)
      final profile = await client
          .from('profiles')
          .select('username, display_name, aura_points')
          .eq('user_id', userId)
          .maybeSingle();

      stats['username'] = profile?['username'] ?? '';
      stats['fullName'] =
          profile?['display_name'] ?? profile?['username'] ?? '';
      stats['aura'] = profile?['aura_points'] ?? 0;

      // Posts count
      final posts = await client
          .from('posts')
          .select('id')
          .eq('user_id', userId);
      stats['posts'] = posts.length;

      // Fetch user's post IDs for likes/comments counting
      final userPostIds = await _getUserPostIds(userId);

      // Likes received — count post_likes where post_id is in user's posts
      if (userPostIds.isNotEmpty) {
        final postLikes = await client
            .from('post_likes')
            .select('post_id')
            .inFilter('post_id', userPostIds);
        stats['likes'] = postLikes.length;

        // Comments count — count comments where post_id is in user's posts
        final comments = await client
            .from('comments')
            .select('id')
            .inFilter('post_id', userPostIds);
        stats['comments'] = comments.length;
      }

      // Followers count
      final followers = await client
          .from('followers')
          .select('follower_id')
          .eq('following_id', userId);
      stats['followers'] = followers.length;

      // Following count
      final following = await client
          .from('followers')
          .select('following_id')
          .eq('follower_id', userId);
      stats['following'] = following.length;

      return stats;
    } catch (e, stack) {
      Logger.error(
        'Failed to fetch profile stats from Supabase. Returning zeros.',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return stats;
    }
  }

  /// Helper to fetch all post IDs authored by a user.
  Future<List<dynamic>> _getUserPostIds(String userId) async {
    try {
      final posts = await SupabaseClientProvider.client!
          .from('posts')
          .select('id')
          .eq('user_id', userId);
      return posts.map((p) => p['id']).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<dynamic>> getAchievements(String userId) async {
    if (!SupabaseClientProvider.isInitialized) {
      return [];
    }

    try {
      final response = await SupabaseClientProvider.client!
          .from('achievements')
          .select('*, user_achievements!inner(*)')
          .eq('user_achievements.user_id', userId);
      return response;
    } catch (e, stack) {
      Logger.error(
        'Failed to fetch achievements from Supabase.',
        error: e,
        stackTrace: stack,
        tag: 'ProfileRepository',
      );
      return [];
    }
  }
}
