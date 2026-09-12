class User {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? avatarUrl;
  final int auraPoints;
  final int steezeLevel;
  final DateTime createdAt;
  final List<String> joinedHoods;
  final List<String> achievements;

  User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.auraPoints = 0,
    this.steezeLevel = 1,
    required this.createdAt,
    this.joinedHoods = const [],
    this.achievements = const [],
  });

  User copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? avatarUrl,
    int? auraPoints,
    int? steezeLevel,
    DateTime? createdAt,
    List<String>? joinedHoods,
    List<String>? achievements,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      auraPoints: auraPoints ?? this.auraPoints,
      steezeLevel: steezeLevel ?? this.steezeLevel,
      createdAt: createdAt ?? this.createdAt,
      joinedHoods: joinedHoods ?? this.joinedHoods,
      achievements: achievements ?? this.achievements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'auraPoints': auraPoints,
      'steezeLevel': steezeLevel,
      'createdAt': createdAt.toIso8601String(),
      'joinedHoods': joinedHoods,
      'achievements': achievements,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      auraPoints: json['auraPoints'] as int? ?? 0,
      steezeLevel: json['steezeLevel'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      joinedHoods: List<String>.from(json['joinedHoods'] ?? []),
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }

  /// Maps a `profiles` row (snake_case) from Supabase.
  factory User.fromSupabaseProfile(Map<String, dynamic> json) {
    return User(
      id: (json['user_id'] ?? json['id'] ?? '') as String,
      fullName:
          (json['display_name'] ??
                  json['full_name'] ??
                  json['username'] ??
                  'User')
              as String,
      username: json['username'] as String? ?? 'user',
      email: json['email'] as String? ?? '',
      avatarUrl: (json['avatar'] ?? json['avatar_url']) as String?,
      auraPoints: json['aura_points'] as int? ?? 0,
      steezeLevel: json['steeze_level'] as int? ?? 1,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
