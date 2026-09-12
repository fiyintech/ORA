class Post {
  final String id;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String content;
  final String? hoodId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likes;
  final int comments;
  final int shares;
  final List<String>? mediaUrls;
  final bool isPublic;
  final bool pendingSync;
  final Set<String> likedBy;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.content,
    this.hoodId,
    required this.createdAt,
    this.updatedAt,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.mediaUrls,
    this.isPublic = true,
    this.pendingSync = false,
    this.likedBy = const {},
  });

  bool isLikedBy(String userId) => likedBy.contains(userId);

  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? content,
    String? hoodId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    int? comments,
    int? shares,
    List<String>? mediaUrls,
    bool? isPublic,
    bool? pendingSync,
    Set<String>? likedBy,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      content: content ?? this.content,
      hoodId: hoodId ?? this.hoodId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      isPublic: isPublic ?? this.isPublic,
      pendingSync: pendingSync ?? this.pendingSync,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'content': content,
      'hoodId': hoodId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'mediaUrls': mediaUrls,
      'isPublic': isPublic,
      'pendingSync': pendingSync,
      'likedBy': likedBy.toList(),
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      content: json['content'] as String,
      hoodId: json['hoodId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      mediaUrls: json['mediaUrls'] != null
          ? List<String>.from(json['mediaUrls'])
          : null,
      isPublic: json['isPublic'] as bool? ?? true,
      pendingSync: json['pendingSync'] as bool? ?? false,
      likedBy: json['likedBy'] != null ? Set<String>.from(json['likedBy']) : {},
    );
  }

  /// Maps a partial `posts` row as joined from notifications.
  factory Post.fromSupabasePreview(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      content: json['content'] as String? ?? '',
      mediaUrls: json['media_urls'] != null
          ? List<String>.from(json['media_urls'] as List)
          : null,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
