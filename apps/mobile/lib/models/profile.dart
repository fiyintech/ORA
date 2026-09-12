/// Database-backed profile model representing the `profiles` table.
///
/// Maps to the Supabase `profiles` table.
class Profile {
  /// Maps to `profiles.user_id` — references the Supabase Auth user ID.
  final String userId;

  /// Maps to `profiles.username`.
  final String username;

  /// Maps to `profiles.display_name`.
  final String displayName;

  /// Maps to `profiles.avatar`.
  final String? avatar;

  /// Maps to `profiles.bio`.
  final String? bio;

  /// Maps to `profiles.aura_points`.
  final int auraPoints;

  /// Maps to `profiles.steeze_level`.
  final int steezeLevel;

  /// Maps to `profiles.verified`.
  final bool verified;

  /// Maps to `profiles.created_at`.
  final DateTime createdAt;

  /// Maps to `profiles.updated_at`.
  final DateTime? updatedAt;

  const Profile({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatar,
    this.bio,
    this.auraPoints = 0,
    this.steezeLevel = 1,
    this.verified = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Profile] from a Supabase row (snake_case keys).
  factory Profile.fromSupabase(Map<String, dynamic> json) {
    return Profile(
      userId: (json['user_id'] ?? json['id']) as String,
      username: json['username'] as String,
      displayName: (json['display_name'] ?? json['full_name'] ?? json['username']) as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      auraPoints: json['aura_points'] as int? ?? 0,
      steezeLevel: json['steeze_level'] as int? ?? 1,
      verified: json['verified'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Creates a [Profile] from a camelCase JSON map (offline/local cache).
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      auraPoints: json['auraPoints'] as int? ?? 0,
      steezeLevel: json['steezeLevel'] as int? ?? 1,
      verified: json['verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'avatar': avatar,
      'bio': bio,
      'auraPoints': auraPoints,
      'steezeLevel': steezeLevel,
      'verified': verified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}