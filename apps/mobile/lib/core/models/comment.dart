import 'package:flutter/painting.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? avatarLetter;
  final List<Color>? avatarColors;
  final String content;
  final String? parentId;
  final bool isEdited;
  final bool isDeleted;
  final bool isPendingSync;
  final int likesCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.avatarLetter,
    this.avatarColors,
    required this.content,
    this.parentId,
    this.isEdited = false,
    this.isDeleted = false,
    this.isPendingSync = false,
    this.likesCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Legacy getter for backward compatibility
  String get text => content;

  /// Legacy getter for backward compatibility
  bool get isPending => isPendingSync;

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? avatarLetter,
    List<Color>? avatarColors,
    String? content,
    String? parentId,
    bool? isEdited,
    bool? isDeleted,
    bool? isPendingSync,
    int? likesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarLetter: avatarLetter ?? this.avatarLetter,
      avatarColors: avatarColors ?? this.avatarColors,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'avatarLetter': avatarLetter,
      'avatarColors': avatarColors?.map((c) => c.toARGB32()).toList(),
      'content': content,
      'parentId': parentId,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isPendingSync': isPendingSync,
      'likesCount': likesCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      avatarLetter: json['avatarLetter'] as String?,
      avatarColors: json['avatarColors'] != null
          ? (json['avatarColors'] as List).map((e) => Color(e as int)).toList()
          : null,
      content: json['content'] as String? ?? json['text'] as String? ?? '',
      parentId: json['parentId'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      isPendingSync: json['isPendingSync'] as bool? ?? false,
      likesCount: json['likesCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Maps a partial `comments` row as joined from notifications.
  factory Comment.fromSupabasePreview(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      content: json['content'] as String? ?? json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
