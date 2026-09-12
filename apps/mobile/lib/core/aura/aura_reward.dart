import 'aura_action.dart';

/// ORA Aura Engine - Reward Definition
///
/// Represents the reward configuration for a specific Aura action.
/// Contains the action, point value, and human-readable description.
class AuraReward {
  final AuraAction action;
  final int points;
  final String description;

  const AuraReward({
    required this.action,
    required this.points,
    required this.description,
  });

  @override
  String toString() {
    return 'AuraReward(action: $action, points: $points, description: $description)';
  }
}
