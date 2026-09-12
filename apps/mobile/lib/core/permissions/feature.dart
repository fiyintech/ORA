/// ORA Permission Engine - Feature Definitions
///
/// This enum defines all features in the ORA app that require permission checks.
/// Each feature can have associated requirements (Aura, Level, Account Age, etc.)
/// that are evaluated by the PermissionEngine.
///
/// Future systems that can plug into this:
/// - Aura Engine: Provides current Aura points and Level
/// - Achievements: Can unlock special permissions
/// - Premium/Subscription: Can grant access to premium features
/// - Verification System: Can unlock verified-only features
/// - Moderator System: Can grant moderation permissions
enum Feature {
  // Community Features
  createHood,
  createEvent,
  pollCreation,

  // Media Features
  viewOnce,
  viewTwice,
  viewFiveTimes,
  timedMedia,

  // Customization
  chatThemes,
  customProfileBanner,
  customProfileFrame,
  hoodCustomization,

  // Moderation
  hoodModeration,
  aiModerator,

  // Special Access
  leaderboardHallOfFame,
  oraLabs,
  verifiedCreator,
  advancedSearch,

  // Communication
  musicRooms,
  voiceRooms,
}