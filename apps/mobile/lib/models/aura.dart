import 'package:flutter/material.dart';

enum AchievementDifficulty { rare, epic, legendary, mythic }

class Achievement {
  final String id;
  final String title;
  final String description;
  final int auraReward;
  final AchievementDifficulty difficulty;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0
  final String? icon;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.auraReward,
    required this.difficulty,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.icon,
  });
}

class AuraHistoryEntry {
  final String id;
  final String action;
  final int auraChange;
  final DateTime timestamp;

  AuraHistoryEntry({
    required this.id,
    required this.action,
    required this.auraChange,
    required this.timestamp,
  });
}

class AuraProgression {
  final int currentAura;
  final int currentLevel;
  final int auraToNextLevel;
  final int totalAuraForNextLevel;

  AuraProgression({
    required this.currentAura,
    required this.currentLevel,
    required this.auraToNextLevel,
    required this.totalAuraForNextLevel,
  });
}

final List<Achievement> dummyAchievements = [
  Achievement(
    id: 'a1',
    title: 'First Impression',
    description: 'Complete your profile',
    auraReward: 20,
    difficulty: AchievementDifficulty.rare,
    isUnlocked: false,
    progress: 0.8,
  ),
  Achievement(
    id: 'a2',
    title: 'Hood Pioneer',
    description: 'Remain active in the same Hood for 30 days',
    auraReward: 120,
    difficulty: AchievementDifficulty.epic,
    isUnlocked: false,
    progress: 0.3,
  ),
  Achievement(
    id: 'a3',
    title: 'Community Pillar',
    description: 'Receive 500 positive reactions',
    auraReward: 250,
    difficulty: AchievementDifficulty.legendary,
    isUnlocked: false,
    progress: 0.05,
  ),
  Achievement(
    id: 'a4',
    title: 'Respected Voice',
    description: 'Receive 1,000 comments across your posts',
    auraReward: 300,
    difficulty: AchievementDifficulty.legendary,
    isUnlocked: false,
    progress: 0.0,
  ),
  Achievement(
    id: 'a5',
    title: 'Legend',
    description: 'Reach Steeze Level 50',
    auraReward: 500,
    difficulty: AchievementDifficulty.legendary,
    isUnlocked: false,
    progress: 0.02,
  ),
  Achievement(
    id: 'a6',
    title: 'ORA Mythic',
    description: 'Reserved for exceptional long-term contribution',
    auraReward: 1000,
    difficulty: AchievementDifficulty.mythic,
    isUnlocked: false,
    progress: 0.0,
  ),
];

final List<AuraHistoryEntry> dummyAuraHistory = [
  AuraHistoryEntry(id: 'h1', action: 'Daily Login', auraChange: 1, timestamp: DateTime.now().subtract(const Duration(hours: 1))),
  AuraHistoryEntry(id: 'h2', action: 'Joined Tech Hood', auraChange: 10, timestamp: DateTime.now().subtract(const Duration(hours: 3))),
  AuraHistoryEntry(id: 'h3', action: 'Received a Like', auraChange: 1, timestamp: DateTime.now().subtract(const Duration(hours: 5))),
  AuraHistoryEntry(id: 'h4', action: 'Created a Post', auraChange: 5, timestamp: DateTime.now().subtract(const Duration(days: 1))),
  AuraHistoryEntry(id: 'h5', action: 'Weekly Streak', auraChange: 15, timestamp: DateTime.now().subtract(const Duration(days: 2))),
];

final AuraProgression dummyProgression = AuraProgression(
  currentAura: 0,
  currentLevel: 1,
  auraToNextLevel: 0,
  totalAuraForNextLevel: 100,
);

String getDifficultyLabel(AchievementDifficulty difficulty) {
  switch (difficulty) {
    case AchievementDifficulty.rare:
      return 'Rare';
    case AchievementDifficulty.epic:
      return 'Epic';
    case AchievementDifficulty.legendary:
      return 'Legendary';
    case AchievementDifficulty.mythic:
      return 'Mythic';
  }
}

Color getDifficultyColor(AchievementDifficulty difficulty) {
  switch (difficulty) {
    case AchievementDifficulty.rare:
      return const Color(0xFF6B3FA0); // Royal Purple
    case AchievementDifficulty.epic:
      return const Color(0xFF2196F3); // Blue
    case AchievementDifficulty.legendary:
      return const Color(0xFFD4AF37); // Champagne Gold
    case AchievementDifficulty.mythic:
      return const Color(0xFFFF6B9D); // Pink/Mythic
  }
}