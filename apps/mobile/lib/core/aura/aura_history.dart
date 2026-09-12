import 'aura_action.dart';

/// ORA Aura Engine - History Entry
///
/// Represents a single Aura transaction in the user's history.
/// Each entry records who earned/removed Aura, for what action,
/// how many points, and when.
class AuraHistory {
  final String id;
  final String userId;
  final AuraAction action;
  final int points;
  final String description;
  final DateTime timestamp;

  AuraHistory({
    required this.id,
    required this.userId,
    required this.action,
    required this.points,
    required this.description,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a copy of this history entry with the given fields overridden.
  AuraHistory copyWith({
    String? id,
    String? userId,
    AuraAction? action,
    int? points,
    String? description,
    DateTime? timestamp,
  }) {
    return AuraHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      points: points ?? this.points,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'AuraHistory(id: $id, userId: $userId, action: $action, '
        'points: $points, description: $description, timestamp: $timestamp)';
  }
}
