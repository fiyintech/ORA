import 'package:flutter/material.dart';

class LeaderboardEntry {
  final String id;
  final String username;
  final String avatarLetter;
  final List<Color> avatarColors;
  final int auraPoints;
  final int steezeLevel;
  final String? prestigeBadge;
  final bool isLegendary;

  LeaderboardEntry({
    required this.id,
    required this.username,
    required this.avatarLetter,
    required this.avatarColors,
    required this.auraPoints,
    required this.steezeLevel,
    this.prestigeBadge,
    this.isLegendary = false,
  });
}

// Mock data removed - leaderboard entries will be loaded from Supabase backend
