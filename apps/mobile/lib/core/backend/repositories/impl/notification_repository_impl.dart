import 'package:mobile/core/backend/repositories/notification_repository.dart';
import 'package:mobile/core/backend/supabase_client.dart';
import 'package:mobile/core/models/comment.dart';
import 'package:mobile/core/models/notification.dart';
import 'package:mobile/core/models/post.dart';
import 'package:mobile/core/models/user.dart' as app_user;
import 'package:mobile/core/utils/backend_error.dart';
import 'package:mobile/core/utils/result.dart';

/// Supabase implementation of [NotificationRepository].
///
/// Loads notifications with joined actor profile and post/comment preview
/// data. Supports real-time updates via Supabase Realtime subscriptions.
class NotificationRepositoryImpl implements NotificationRepository {
  // ──────────────────────────────────────────────────────────────
  // Load Notifications
  // ──────────────────────────────────────────────────────────────

  /// Loads notifications for a user with joined actor and content data.
  /// Returns notifications ordered by newest first.
  @override
  Future<Result<List<NotificationModel>>> loadNotifications(
    String userId,
  ) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(<NotificationModel>[]);
    }

    try {
      final client = SupabaseClientProvider.client!;

      final response = await client
          .from('notifications')
          .select('''
            *,
            actor:profiles!notifications_actor_id_fkey (
              user_id,
              username,
              display_name,
              avatar
            ),
            post:posts!notifications_post_id_fkey (
              id,
              content,
              media_urls
            ),
            comment:comments!notifications_comment_id_fkey (
              id,
              content
            )
          ''')
          .eq('recipient_id', userId)
          .order('created_at', ascending: false);

      final notifications = response.map((row) {
        return _mapNotificationFromRow(row);
      }).toList();

      return Result.success(notifications);
    } catch (e, stack) {
      logBackendError(
        'loadNotifications',
        e,
        stack,
        tag: 'NotificationRepository',
      );
      return Result.failure(backendFailure(e, stack));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Mark as Read
  // ──────────────────────────────────────────────────────────────

  /// Marks a single notification as read.
  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(null);
    }

    try {
      final client = SupabaseClientProvider.client!;

      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      return Result.success(null);
    } catch (e, stack) {
      logBackendError('markAsRead', e, stack, tag: 'NotificationRepository');
      return Result.failure(backendFailure(e, stack));
    }
  }

  /// Marks all notifications as read for a user.
  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(null);
    }

    try {
      final client = SupabaseClientProvider.client!;

      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('is_read', false);

      return Result.success(null);
    } catch (e, stack) {
      logBackendError('markAllAsRead', e, stack, tag: 'NotificationRepository');
      return Result.failure(backendFailure(e, stack));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Delete Notification
  // ──────────────────────────────────────────────────────────────

  /// Deletes a notification.
  @override
  Future<Result<void>> deleteNotification(String notificationId) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(null);
    }

    try {
      final client = SupabaseClientProvider.client!;

      await client.from('notifications').delete().eq('id', notificationId);

      return Result.success(null);
    } catch (e, stack) {
      logBackendError(
        'deleteNotification',
        e,
        stack,
        tag: 'NotificationRepository',
      );
      return Result.failure(backendFailure(e, stack));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Unread Count
  // ──────────────────────────────────────────────────────────────

  /// Gets the count of unread notifications for a user.
  @override
  Future<Result<int>> getUnreadCount(String userId) async {
    if (!SupabaseClientProvider.isInitialized) {
      return Result.success(0);
    }

    try {
      final client = SupabaseClientProvider.client!;

      final response = await client
          .from('notifications')
          .select()
          .eq('recipient_id', userId)
          .eq('is_read', false);

      return Result.success(response.length);
    } catch (e, stack) {
      logBackendError(
        'getUnreadCount',
        e,
        stack,
        tag: 'NotificationRepository',
      );
      return Result.failure(backendFailure(e, stack));
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Realtime Subscription
  // ──────────────────────────────────────────────────────────────

  /// Streams real-time notifications for a user.
  /// Emits new notifications as they are created.
  @override
  Stream<NotificationModel> watchNotifications(String userId) {
    if (!SupabaseClientProvider.isInitialized) {
      return const Stream.empty();
    }

    final client = SupabaseClientProvider.client!;

    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .asyncExpand((rows) async* {
          for (final row in rows) {
            try {
              yield _mapNotificationFromRow(row);
            } catch (e, stack) {
              logBackendError(
                'watchNotifications.map',
                e,
                stack,
                tag: 'NotificationRepository',
              );
            }
          }
        });
  }

  // ──────────────────────────────────────────────────────────────
  // Mapping Helper
  // ──────────────────────────────────────────────────────────────

  /// Maps a Supabase row (with joined data) to a [NotificationModel].
  NotificationModel _mapNotificationFromRow(Map<String, dynamic> row) {
    final actorData = row['actor'] as Map<String, dynamic>?;
    final postData = row['post'] as Map<String, dynamic>?;
    final commentData = row['comment'] as Map<String, dynamic>?;

    return NotificationModel(
      id: row['id'] as String,
      recipientId: row['recipient_id'] as String,
      actorId: row['actor_id'] as String,
      postId: row['post_id'] as String?,
      commentId: row['comment_id'] as String?,
      type: NotificationType.fromString(row['type'] as String),
      isRead: row['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      actor: actorData != null
          ? app_user.User.fromSupabaseProfile(actorData)
          : null,
      post: postData != null ? Post.fromSupabasePreview(postData) : null,
      comment: commentData != null
          ? Comment.fromSupabasePreview(commentData)
          : null,
    );
  }
}
