import 'package:mobile/core/backend/supabase_client.dart';
import 'package:mobile/core/backend/repositories/user_repository.dart';
import 'package:mobile/core/models/user.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:mobile/core/utils/result.dart';

/// Repository for user operations backed by Supabase.
///
/// Queries `profiles` table when Supabase is initialized.
class UserRepositoryImpl implements UserRepository {
  @override
  Future<Result<User>> create(User user) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(user);
    }

    try {
      await SupabaseClientProvider.client!
          .from('profiles')
          .upsert({
            'user_id': user.id,
            'username': user.username,
            'display_name': user.fullName,
            'avatar': user.avatarUrl,
            'aura_points': user.auraPoints,
            'steeze_level': user.steezeLevel,
          }, onConflict: 'user_id');
      return Result.success(user);
    } catch (e, stack) {
      Logger.error(
        'Failed to create user in Supabase.',
        error: e,
        stackTrace: stack,
        tag: 'UserRepository',
      );
      return Result.failure(Failure('Failed to create user: $e'));
    }
  }

  @override
  Future<Result<User?>> getById(String id) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(null);
    }

    try {
      final response = await SupabaseClientProvider.client!
          .from('profiles')
          .select()
          .eq('user_id', id)
          .maybeSingle();

      if (response == null) {
        return Result.success(null);
      }

      return Result.success(User(
        id: response['user_id'] as String,
        fullName: response['display_name'] as String? ?? response['username'] as String? ?? 'User',
        username: response['username'] as String? ?? '',
        email: '',
        avatarUrl: response['avatar'] as String?,
        auraPoints: response['aura_points'] as int? ?? 0,
        steezeLevel: response['steeze_level'] as int? ?? 1,
        createdAt: DateTime.tryParse(response['created_at'] as String? ?? '') ?? DateTime.now(),
      ));
    } catch (e, stack) {
      Logger.error(
        'Failed to get user from Supabase.',
        error: e,
        stackTrace: stack,
        tag: 'UserRepository',
      );
      return Result.success(null);
    }
  }

  @override
  Future<Result<User>> update(User user) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(user);
    }

    try {
      await SupabaseClientProvider.client!
          .from('profiles')
          .update({
            'username': user.username,
            'display_name': user.fullName,
            'avatar': user.avatarUrl,
            'aura_points': user.auraPoints,
            'steeze_level': user.steezeLevel,
          })
          .eq('user_id', user.id);
      return Result.success(user);
    } catch (e, stack) {
      Logger.error(
        'Failed to update user in Supabase.',
        error: e,
        stackTrace: stack,
        tag: 'UserRepository',
      );
      return Result.failure(Failure('Failed to update user: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(null);
    }

    try {
      await SupabaseClientProvider.client!
          .from('profiles')
          .delete()
          .eq('user_id', id);
      return Result.success(null);
    } catch (e, stack) {
      Logger.error(
        'Failed to delete user from Supabase.',
        error: e,
        stackTrace: stack,
        tag: 'UserRepository',
      );
      return Result.failure(Failure('Failed to delete user: $e'));
    }
  }

  @override
  Future<Result<List<User>>> search(String query) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success([]);
    }

    try {
      final response = await SupabaseClientProvider.client!
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(20);

      final users = response.map((r) => User(
        id: r['user_id'] as String,
        fullName: r['display_name'] as String? ?? r['username'] as String? ?? 'User',
        username: r['username'] as String? ?? '',
        email: '',
        avatarUrl: r['avatar'] as String?,
        auraPoints: r['aura_points'] as int? ?? 0,
        steezeLevel: r['steeze_level'] as int? ?? 1,
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
      )).toList();

      return Result.success(users);
    } catch (e, stack) {
      Logger.error(
        'Failed to search users in Supabase.',
        error: e,
        stackTrace: stack,
        tag: 'UserRepository',
      );
      return Result.success([]);
    }
  }
}