import 'package:mobile/core/models/notification.dart';
import 'package:mobile/core/utils/result.dart';

/// Repository interface for notification operations.
abstract class NotificationRepository {
  /// Loads notifications for a user with joined actor and content data.
  /// Returns notifications ordered by newest first.
  Future<Result<List<NotificationModel>>> loadNotifications(String userId);

  /// Marks a single notification as read.
  Future<Result<void>> markAsRead(String notificationId);

  /// Marks all notifications as read for a user.
  Future<Result<void>> markAllAsRead(String userId);

  /// Deletes a notification.
  Future<Result<void>> deleteNotification(String notificationId);

  /// Gets the count of unread notifications for a user.
  Future<Result<int>> getUnreadCount(String userId);

  /// Streams real-time notifications for a user.
  /// Emits new notifications as they are created.
  Stream<NotificationModel> watchNotifications(String userId);
}
