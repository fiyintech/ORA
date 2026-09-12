import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isMine = false,
  });
}

class Conversation {
  final String id;
  final String username;
  final String avatarLetter;
  final List<Color> avatarColors;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String timeDisplay;
  final int unreadCount;
  final bool isPinned;
  final String category; // 'chats', 'hoods', 'favorites'
  final List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.username,
    required this.avatarLetter,
    required this.avatarColors,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.timeDisplay,
    this.unreadCount = 0,
    this.isPinned = false,
    this.category = 'chats',
    required this.messages,
  });
}

final List<Conversation> dummyConversations = [
  Conversation(
    id: '1',
    username: 'Maya',
    avatarLetter: 'M',
    avatarColors: const [Color(0xFFD4AF37), Color(0xFFE8C547)],
    lastMessage: 'Are you coming to the hood meetup?',
    lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
    timeDisplay: '5m',
    unreadCount: 2,
    isPinned: true,
    category: 'chats',
    messages: [
      ChatMessage(id: 'm1', senderId: 'me', text: 'Hey Maya! What time is the meetup?', timestamp: DateTime.now().subtract(const Duration(hours: 1)), isMine: true),
      ChatMessage(id: 'm2', senderId: 'maya', text: 'Starts at 7pm at the usual spot 🔥', timestamp: DateTime.now().subtract(const Duration(minutes: 45))),
      ChatMessage(id: 'm3', senderId: 'me', text: "Say less, I'll be there 🫡", timestamp: DateTime.now().subtract(const Duration(minutes: 30)), isMine: true),
      ChatMessage(id: 'm4', senderId: 'maya', text: 'Are you coming to the hood meetup?', timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
    ],
  ),
  Conversation(
    id: '2',
    username: 'Victor',
    avatarLetter: 'V',
    avatarColors: const [Color(0xFF6B3FA0), Color(0xFF8B5CF6)],
    lastMessage: 'I just hit Steeze Level 2! 🏆',
    lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
    timeDisplay: '15m',
    unreadCount: 0,
    isPinned: true,
    category: 'chats',
    messages: [
      ChatMessage(id: 'v1', senderId: 'victor', text: 'Bro have you seen the leaderboard?', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
      ChatMessage(id: 'v2', senderId: 'me', text: "Not yet, what's happening?", timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)), isMine: true),
      ChatMessage(id: 'v3', senderId: 'victor', text: "I'm moving up fast. The grind is real.", timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30))),
      ChatMessage(id: 'v4', senderId: 'me', text: 'Good job bro 🫡', timestamp: DateTime.now().subtract(const Duration(minutes: 20)), isMine: true),
      ChatMessage(id: 'v5', senderId: 'victor', text: 'I just hit Steeze Level 2! 🏆', timestamp: DateTime.now().subtract(const Duration(minutes: 15))),
    ],
  ),
  Conversation(
    id: '3',
    username: 'James',
    avatarLetter: 'J',
    avatarColors: const [Color(0xFF6B3FA0), Color(0xFF8B5CF6)],
    lastMessage: 'The hood is active tonight',
    lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
    timeDisplay: '1h',
    unreadCount: 0,
    isPinned: false,
    category: 'chats',
    messages: [
      ChatMessage(id: 'j1', senderId: 'james', text: 'Yo! What\'s good?', timestamp: DateTime.now().subtract(const Duration(hours: 3))),
      ChatMessage(id: 'j2', senderId: 'me', text: 'Not much, chilling. You?', timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)), isMine: true),
      ChatMessage(id: 'j3', senderId: 'james', text: 'The hood is active tonight', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
    ],
  ),
  Conversation(
    id: '4',
    username: 'Ada',
    avatarLetter: 'A',
    avatarColors: const [Color(0xFFD4AF37), Color(0xFFE8C547)],
    lastMessage: 'Your aura is glowing bestie ✨',
    lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
    timeDisplay: '2h',
    unreadCount: 1,
    isPinned: false,
    category: 'chats',
    messages: [
      ChatMessage(id: 'a1', senderId: 'ada', text: 'Girllll have you seen the new features?', timestamp: DateTime.now().subtract(const Duration(hours: 3))),
      ChatMessage(id: 'a2', senderId: 'me', text: "Not yet, what's new?", timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)), isMine: true),
      ChatMessage(id: 'a3', senderId: 'ada', text: 'Your aura is glowing bestie ✨', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    ],
  ),
  Conversation(
    id: '5',
    username: 'Kelvin',
    avatarLetter: 'K',
    avatarColors: const [Color(0xFF6B3FA0), Color(0xFF8B5CF6)],
    lastMessage: 'Check the leaderboard rn 👀',
    lastMessageTime: DateTime.now().subtract(const Duration(hours: 4)),
    timeDisplay: '4h',
    unreadCount: 0,
    isPinned: false,
    category: 'hoods',
    messages: [
      ChatMessage(id: 'k1', senderId: 'kelvin', text: 'Yo! Did you see what happened?', timestamp: DateTime.now().subtract(const Duration(hours: 5))),
      ChatMessage(id: 'k2', senderId: 'me', text: "What's up?", timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 30)), isMine: true),
      ChatMessage(id: 'k3', senderId: 'kelvin', text: 'Check the leaderboard rn 👀', timestamp: DateTime.now().subtract(const Duration(hours: 4))),
    ],
  ),
  Conversation(
    id: '6',
    username: 'Zuri',
    avatarLetter: 'Z',
    avatarColors: const [Color(0xFFD4AF37), Color(0xFFE8C547)],
    lastMessage: 'Reputation is everything in this app',
    lastMessageTime: DateTime.now().subtract(const Duration(hours: 6)),
    timeDisplay: '6h',
    unreadCount: 0,
    isPinned: false,
    category: 'favorites',
    messages: [
      ChatMessage(id: 'z1', senderId: 'zuri', text: 'This app is something else', timestamp: DateTime.now().subtract(const Duration(hours: 7))),
      ChatMessage(id: 'z2', senderId: 'me', text: 'Right? The concept is fire', timestamp: DateTime.now().subtract(const Duration(hours: 6, minutes: 30)), isMine: true),
      ChatMessage(id: 'z3', senderId: 'zuri', text: 'Reputation is everything in this app', timestamp: DateTime.now().subtract(const Duration(hours: 6))),
    ],
  ),
];

List<Conversation> getFilteredConversations(String filter) {
  if (filter == 'all') return dummyConversations;
  return dummyConversations.where((c) => c.category == filter).toList();
}