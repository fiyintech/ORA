class LeaderboardEntryModel {
  final String id;
  final String username;
  final String avatarLetter;
  final int auraPoints;
  final int steezeLevel;
  final String? prestigeBadge;
  final bool isLegendary;

  LeaderboardEntryModel({
    required this.id,
    required this.username,
    required this.avatarLetter,
    required this.auraPoints,
    required this.steezeLevel,
    this.prestigeBadge,
    this.isLegendary = false,
  });
}