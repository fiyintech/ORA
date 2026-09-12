class AchievementModel {
  final String id;
  final String title;
  final String description;
  final int auraReward;
  final String difficulty; // 'Rare', 'Epic', 'Legendary', 'Mythic'
  final bool isUnlocked;
  final double progress;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.auraReward,
    required this.difficulty,
    this.isUnlocked = false,
    this.progress = 0.0,
  });
}