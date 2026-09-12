import 'ora_event.dart';

/// Event emitted when a post is created.
class PostCreatedEvent extends ORAEvent {
  /// ID of the created post.
  final String postId;

  /// ID of the user who created the post.
  final String userId;

  /// ID of the hood where the post was created, if any.
  final String? hoodId;

  /// Creates a new PostCreatedEvent.
  PostCreatedEvent({
    required this.postId,
    required this.userId,
    this.hoodId,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'PostCreatedEvent(postId: $postId, userId: $userId, hoodId: $hoodId)';
  }
}

/// Event emitted when a post is deleted.
class PostDeletedEvent extends ORAEvent {
  /// ID of the deleted post.
  final String postId;

  /// ID of the user who deleted the post.
  final String userId;

  /// Reason for deletion, if any.
  final String? reason;

  /// Creates a new PostDeletedEvent.
  PostDeletedEvent({
    required this.postId,
    required this.userId,
    this.reason,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'PostDeletedEvent(postId: $postId, userId: $userId, reason: $reason)';
  }
}

/// Event emitted when a post is liked.
class PostLikedEvent extends ORAEvent {
  /// ID of the liked post.
  final String postId;

  /// ID of the user who liked the post.
  final String userId;

  /// ID of the post author.
  final String authorId;

  /// Creates a new PostLikedEvent.
  PostLikedEvent({
    required this.postId,
    required this.userId,
    required this.authorId,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'PostLikedEvent(postId: $postId, userId: $userId, authorId: $authorId)';
  }
}

/// Event emitted when a comment is created.
class CommentCreatedEvent extends ORAEvent {
  /// ID of the created comment.
  final String commentId;

  /// ID of the post being commented on.
  final String postId;

  /// ID of the user who created the comment.
  final String userId;

  /// Creates a new CommentCreatedEvent.
  CommentCreatedEvent({
    required this.commentId,
    required this.postId,
    required this.userId,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'CommentCreatedEvent(commentId: $commentId, postId: $postId, userId: $userId)';
  }
}

/// Event emitted when a user follows another user.
class UserFollowedEvent extends ORAEvent {
  /// ID of the user who initiated the follow.
  final String followerId;

  /// ID of the user being followed.
  final String followedId;

  /// Creates a new UserFollowedEvent.
  UserFollowedEvent({
    required this.followerId,
    required this.followedId,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'UserFollowedEvent(followerId: $followerId, followedId: $followedId)';
  }
}

/// Event emitted when a user joins a hood.
class UserJoinedHoodEvent extends ORAEvent {
  /// ID of the user who joined the hood.
  final String userId;

  /// ID of the hood that was joined.
  final String hoodId;

  /// Creates a new UserJoinedHoodEvent.
  UserJoinedHoodEvent({
    required this.userId,
    required this.hoodId,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'UserJoinedHoodEvent(userId: $userId, hoodId: $hoodId)';
  }
}

/// Event emitted when a hood is created.
class HoodCreatedEvent extends ORAEvent {
  /// ID of the created hood.
  final String hoodId;

  /// ID of the user who created the hood.
  final String creatorId;

  /// Name of the created hood.
  final String hoodName;

  /// Creates a new HoodCreatedEvent.
  HoodCreatedEvent({
    required this.hoodId,
    required this.creatorId,
    required this.hoodName,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'HoodCreatedEvent(hoodId: $hoodId, creatorId: $creatorId, hoodName: $hoodName)';
  }
}

/// Event emitted when an achievement is unlocked.
class AchievementUnlockedEvent extends ORAEvent {
  /// ID of the unlocked achievement.
  final String achievementId;

  /// ID of the user who unlocked the achievement.
  final String userId;

  /// Name of the achievement.
  final String achievementName;

  /// Creates a new AchievementUnlockedEvent.
  AchievementUnlockedEvent({
    required this.achievementId,
    required this.userId,
    required this.achievementName,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'AchievementUnlockedEvent(achievementId: $achievementId, userId: $userId, achievementName: $achievementName)';
  }
}

/// Event emitted when aura is awarded to a user.
class AuraAwardedEvent extends ORAEvent {
  /// ID of the user who received the aura.
  final String userId;

  /// Amount of aura awarded.
  final int auraAmount;

  /// Reason for the aura award.
  final String reason;

  /// Source of the aura award (e.g., 'post_created', 'comment_liked').
  final String source;

  /// Creates a new AuraAwardedEvent.
  AuraAwardedEvent({
    required this.userId,
    required this.auraAmount,
    required this.reason,
    required this.source,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'AuraAwardedEvent(userId: $userId, auraAmount: $auraAmount, reason: $reason, source: $source)';
  }
}

/// Event emitted when a notification is created.
class NotificationCreatedEvent extends ORAEvent {
  /// ID of the created notification.
  final String notificationId;

  /// ID of the user who should receive the notification.
  final String userId;

  /// Type of notification (e.g., 'like', 'comment', 'follow').
  final String notificationType;

  /// Title of the notification.
  final String title;

  /// Body/content of the notification.
  final String body;

  /// Creates a new NotificationCreatedEvent.
  NotificationCreatedEvent({
    required this.notificationId,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.body,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'NotificationCreatedEvent(notificationId: $notificationId, userId: $userId, type: $notificationType)';
  }
}

/// Event emitted when user permissions change.
class PermissionChangedEvent extends ORAEvent {
  /// ID of the user whose permissions changed.
  final String userId;

  /// Type of permission that changed.
  final String permissionType;

  /// New value of the permission.
  final bool newValue;

  /// Previous value of the permission.
  final bool? previousValue;

  /// Creates a new PermissionChangedEvent.
  PermissionChangedEvent({
    required this.userId,
    required this.permissionType,
    required this.newValue,
    this.previousValue,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'PermissionChangedEvent(userId: $userId, permissionType: $permissionType, newValue: $newValue)';
  }
}

/// Event emitted when a user logs in.
class UserLoggedInEvent extends ORAEvent {
  /// ID of the user who logged in.
  final String userId;

  /// Device/platform used for login.
  final String? device;

  /// Creates a new UserLoggedInEvent.
  UserLoggedInEvent({
    required this.userId,
    this.device,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'UserLoggedInEvent(userId: $userId, device: $device)';
  }
}

/// Event emitted when a user logs out.
class UserLoggedOutEvent extends ORAEvent {
  /// ID of the user who logged out.
  final String userId;

  /// Reason for logout, if any.
  final String? reason;

  /// Creates a new UserLoggedOutEvent.
  UserLoggedOutEvent({
    required this.userId,
    this.reason,
    super.id,
    super.timestamp,
    super.metadata,
  });

  @override
  String toString() {
    return 'UserLoggedOutEvent(userId: $userId, reason: $reason)';
  }
}