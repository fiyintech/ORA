import 'package:flutter/material.dart';

class HoodPost {
  final String id;
  final String username;
  final String avatarLetter;
  final List<Color> avatarColors;
  final int auraBadge;
  final String time;
  final String text;
  final int likes;
  final int comments;

  HoodPost({
    required this.id,
    required this.username,
    required this.avatarLetter,
    required this.avatarColors,
    required this.auraBadge,
    required this.time,
    required this.text,
    this.likes = 0,
    this.comments = 0,
  });
}

class HoodMember {
  final String id;
  final String username;
  final String avatarLetter;
  final List<Color> avatarColors;
  final int auraPoints;
  final bool isOnline;

  HoodMember({
    required this.id,
    required this.username,
    required this.avatarLetter,
    required this.avatarColors,
    required this.auraPoints,
    this.isOnline = false,
  });
}

class Hood {
  final String id;
  final String name;
  final String category;
  final String description;
  final int memberCount;
  final bool isJoined;
  final List<Color> bannerColors;
  final IconData icon;
  final int unreadCount;
  final String lastActivity;
  final List<HoodPost> posts;
  final List<HoodMember> members;

  Hood({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.memberCount,
    this.isJoined = false,
    required this.bannerColors,
    required this.icon,
    this.unreadCount = 0,
    this.lastActivity = '',
    required this.posts,
    required this.members,
  });
}

// Mock data removed - hoods will be loaded from Supabase backend
