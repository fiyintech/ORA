import 'aura_action.dart';
import 'aura_history.dart';
import 'aura_reward.dart';

// ORA Aura Engine - Core Logic
//
// Centralized Aura awarding and tracking system.
// All Aura rules are defined in one place for easy maintenance.
//
// Future systems that can plug into this:
//
// 1. Stories:
//    - Award Aura when a story is viewed, reacted to, or shared
//    - Example: auraEngine.award(userId, AuraAction.storyViewed)
//
// 2. Chat:
//    - Award Aura for first message in a conversation, daily chat streaks
//    - Example: auraEngine.award(userId, AuraAction.firstChatMessage)
//
// 3. Hoods:
//    - Award Aura for joining a Hood, creating a Hood, or Hood milestones
//    - Example: auraEngine.award(userId, AuraAction.joinHood)
//
// 4. Achievements:
//    - Award variable Aura when an achievement is unlocked
//    - Example: auraEngine.award(userId, AuraAction.achievementUnlocked,
//            customPoints: achievement.auraReward)
//
// 5. Notifications:
//    - Award Aura for referring friends who sign up via notification invites
//    - Example: auraEngine.award(userId, AuraAction.inviteFriend)
//
// To integrate these systems:
// 1. Call auraEngine.award() or auraEngine.remove() with the appropriate
//    AuraAction
// 2. For variable rewards (e.g. achievements), pass customPoints
// 3. All rules remain centralized in this engine
// 4. UI can read totals via auraEngine.calculateTotal(userId)

/// ORA Aura Engine
///
/// Centralized system for awarding, removing, and tracking Aura points.
/// Uses placeholder in-memory storage (to be replaced with local persistence).
class AuraEngine {
  /// Singleton pattern for global access
  static final AuraEngine _instance = AuraEngine._internal();
  factory AuraEngine() => _instance;
  AuraEngine._internal();

  // --- Reward Table (ONE place for all Aura values) ---

  static const Map<AuraAction, int> _rewards = {
    AuraAction.dailyLogin: 2,
    AuraAction.createPost: 5,
    AuraAction.deletePost: 0,
    AuraAction.receiveLike: 1,
    AuraAction.receiveComment: 3,
    AuraAction.receiveShare: 2,
    AuraAction.joinHood: 10,
    AuraAction.createHood: 50,
    AuraAction.followUser: 5,
    AuraAction.completeProfile: 25,
    AuraAction.achievementUnlocked: 0, // variable — pass customPoints
    AuraAction.dailyStreak: 10,
    AuraAction.seasonReward: 100,
    AuraAction.reportResolved: 15,
    AuraAction.inviteFriend: 30,
  };

  static const Map<AuraAction, String> _descriptions = {
    AuraAction.dailyLogin: 'Daily login bonus',
    AuraAction.createPost: 'Created a post',
    AuraAction.deletePost: 'Deleted a post',
    AuraAction.receiveLike: 'Received a like',
    AuraAction.receiveComment: 'Received a comment',
    AuraAction.receiveShare: 'Post was shared',
    AuraAction.joinHood: 'Joined a Hood',
    AuraAction.createHood: 'Created a Hood',
    AuraAction.followUser: 'Followed a user',
    AuraAction.completeProfile: 'Completed profile',
    AuraAction.achievementUnlocked: 'Achievement unlocked',
    AuraAction.dailyStreak: 'Daily streak maintained',
    AuraAction.seasonReward: 'Season reward',
    AuraAction.reportResolved: 'Report resolved',
    AuraAction.inviteFriend: 'Friend invited',
  };

  // --- Placeholder local persistence (in-memory) ---

  final List<AuraHistory> _history = [];
  int _idCounter = 0;

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
  }

  /// Clears all stored history.
  ///
  /// Useful for testing and resetting engine state.
  void clear() {
    _history.clear();
    _idCounter = 0;
  }

  // --- Public API ---

  /// Returns the [AuraReward] configuration for the given [action].
  ///
  /// Pass [customPoints] to override the default reward value
  /// (used for variable rewards like [AuraAction.achievementUnlocked]).
  AuraReward getReward(AuraAction action, {int? customPoints}) {
    final points = customPoints ?? _rewards[action] ?? 0;
    return AuraReward(
      action: action,
      points: points,
      description: _descriptions[action] ?? action.name,
    );
  }

  /// Awards Aura points to [userId] for the given [action].
  ///
  /// Pass [customPoints] to override the default reward value.
  /// Pass [description] to override the default description.
  ///
  /// Returns the created [AuraHistory] entry.
  AuraHistory award(
    String userId,
    AuraAction action, {
    int? customPoints,
    String? description,
  }) {
    final reward = getReward(action, customPoints: customPoints);
    final history = AuraHistory(
      id: _generateId(),
      userId: userId,
      action: action,
      points: reward.points,
      description: description ?? reward.description,
    );
    _history.add(history);
    return history;
  }

  /// Removes Aura points from [userId] for the given [action].
  ///
  /// Pass [customPoints] to override the default removal amount.
  /// Pass [description] to override the default description.
  ///
  /// Returns the created [AuraHistory] entry (with negative points).
  AuraHistory remove(
    String userId,
    AuraAction action, {
    int? customPoints,
    String? description,
  }) {
    final reward = getReward(action, customPoints: customPoints);
    final history = AuraHistory(
      id: _generateId(),
      userId: userId,
      action: action,
      points: -reward.points,
      description: description ?? reward.description,
    );
    _history.add(history);
    return history;
  }

  /// Calculates the total Aura points for [userId].
  ///
  /// Sums all positive and negative entries in the user's history.
  int calculateTotal(String userId) {
    return _history
        .where((h) => h.userId == userId)
        .fold(0, (sum, h) => sum + h.points);
  }

  /// Returns the full Aura history for [userId].
  List<AuraHistory> history(String userId) {
    return List.unmodifiable(
      _history.where((h) => h.userId == userId),
    );
  }
}
