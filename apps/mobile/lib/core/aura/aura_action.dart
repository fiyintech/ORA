/// ORA Aura Engine - Action Definitions
///
/// Defines all actions in the ORA app that can award or remove Aura points.
/// Each action has an associated reward value defined in the AuraEngine.
enum AuraAction {
  // Engagement
  dailyLogin,
  createPost,
  deletePost,
  receiveLike,
  receiveComment,
  receiveShare,

  // Community
  joinHood,
  createHood,
  followUser,

  // Profile
  completeProfile,

  // Achievements & Progression
  achievementUnlocked,
  dailyStreak,
  seasonReward,

  // Moderation & Trust
  reportResolved,

  // Growth
  inviteFriend,
}
