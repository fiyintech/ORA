import 'package:mobile/core/models/comment.dart';
import 'package:mobile/core/models/post.dart';
import 'package:mobile/core/models/user.dart';

/// Notification types supported by the ORA notification system.
enum NotificationType {
  like('like'),
  comment('comment'),
  reply('reply'),
  follow('follow');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.like,
    );
  }
}

/// Represents a notification in the ORA system.
class NotificationModel {
  final String id;
  final String recipientId;
  final String actorId;
  final String? postId;
  final String? commentId;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  // Joined data (not stored in DB, populated by queries)
  final User? actor;
  final Post? post;
  final Comment? comment;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.actorId,
    this.postId,
    this.commentId,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.actor,
    this.post,
    this.comment,
  });

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? actorId,
    String? postId,
    String? commentId,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    User? actor,
    Post? post,
    Comment? comment,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      actorId: actorId ?? this.actorId,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actor: actor ?? this.actor,
      post: post ?? this.post,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'actorId': actorId,
      'postId': postId,
      'commentId': commentId,
      'type': type.value,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (actor != null) 'actor': actor!.toJson(),
      if (post != null) 'post': post!.toJson(),
      if (comment != null) 'comment': comment!.toJson(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      actorId: json['actor_id'] as String,
      postId: json['post_id'] as String?,
      commentId: json['comment_id'] as String?,
      type: NotificationType.fromString(json['type'] as String),
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      actor: json['actor'] != null
          ? User.fromSupabaseProfile(json['actor'] as Map<String, dynamic>)
          : null,
      post: json['post'] != null
          ? Post.fromSupabasePreview(json['post'] as Map<String, dynamic>)
          : null,
      comment: json['comment'] != null
          ? Comment.fromSupabasePreview(json['comment'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Returns a human-readable description of the notification.
  String getDescription() {
    final actorName = actor?.username ?? 'Someone';

    switch (type) {
      case NotificationType.like:
        return '$actorName liked your post';
      case NotificationType.comment:
        return '$actorName commented on your post';
      case NotificationType.reply:
        return '$actorName replied to your comment';
      case NotificationType.follow:
        return '$actorName started following you';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, isRead: $isRead, createdAt: $createdAt)';
  }
}
