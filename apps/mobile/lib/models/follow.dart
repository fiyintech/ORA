/// Database-backed model representing the `followers` table.
///
/// Maps to the Supabase `followers` table.
class Follow {
  /// Maps to `followers.follower_id` — the user who initiated the follow.
  final String followerId;

  /// Maps to `followers.following_id` — the user being followed.
  final String followingId;

  /// Maps to `followers.created_at`.
  final DateTime createdAt;

  const Follow({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  /// Creates a [Follow] from a Supabase row (snake_case keys).
  factory Follow.fromSupabase(Map<String, dynamic> json) {
    return Follow(
      followerId: json['follower_id'] as String,
      followingId: json['following_id'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Creates a [Follow] from a camelCase JSON map (offline/local cache).
  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      followerId: json['followerId'] as String,
      followingId: json['followingId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}