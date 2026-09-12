// ORA Permission Engine - Core Permission Logic
//
// This engine evaluates whether a user can access specific features
// based on their attributes (Aura, Level, Account Age, etc.)
//
// Future systems that can plug into this:
// - Aura Engine: Provides current Aura points and Level
// - Achievements: Can unlock special permissions
// - Premium/Subscription: Can grant access to premium features
// - Verification System: Can unlock verified-only features
// - Moderator System: Can grant moderation permissions
import 'feature.dart';
import 'permission_result.dart';

/// Represents a user for permission checking
/// This is a simplified version - in production this would come from the user model
class PermissionUser {
  final int auraPoints;
  final int level;
  final int accountAgeInDays;
  final bool isModerator;
  final bool isVerified;
  final bool hasPremium;
  final List<String> unlockedAchievements;

  const PermissionUser({
    required this.auraPoints,
    required this.level,
    required this.accountAgeInDays,
    this.isModerator = false,
    this.isVerified = false,
    this.hasPremium = false,
    this.unlockedAchievements = const [],
  });
}

/// ORA Permission Engine
///
/// Centralized permission checking system that evaluates user access to features.
/// All permission rules are defined in one place for easy maintenance.
class PermissionEngine {
  /// Singleton pattern for global access
  static final PermissionEngine _instance = PermissionEngine._internal();
  factory PermissionEngine() => _instance;
  PermissionEngine._internal();

  /// Main method to check if a user can use a specific feature
  ///
  /// [feature] - The feature to check permission for
  /// [user] - The user to check permissions for
  ///
  /// Returns a [PermissionResult] indicating whether access is allowed
  PermissionResult canUseFeature(Feature feature, PermissionUser user) {
    // Check feature-specific requirements
    switch (feature) {
      // Community Features
      case Feature.createHood:
        return _checkCreateHood(user);
      case Feature.createEvent:
        return _checkCreateEvent(user);
      case Feature.pollCreation:
        return _checkPollCreation(user);

      // Media Features
      case Feature.viewOnce:
        return _checkViewOnce(user);
      case Feature.viewTwice:
        return _checkViewTwice(user);
      case Feature.viewFiveTimes:
        return _checkViewFiveTimes(user);
      case Feature.timedMedia:
        return _checkTimedMedia(user);

      // Customization
      case Feature.chatThemes:
        return _checkChatThemes(user);
      case Feature.customProfileBanner:
        return _checkCustomProfileBanner(user);
      case Feature.customProfileFrame:
        return _checkCustomProfileFrame(user);
      case Feature.hoodCustomization:
        return _checkHoodCustomization(user);

      // Moderation
      case Feature.hoodModeration:
        return _checkHoodModeration(user);
      case Feature.aiModerator:
        return _checkAIModerator(user);

      // Special Access
      case Feature.leaderboardHallOfFame:
        return _checkLeaderboardHallOfFame(user);
      case Feature.oraLabs:
        return _checkOraLabs(user);
      case Feature.verifiedCreator:
        return _checkVerifiedCreator(user);
      case Feature.advancedSearch:
        return _checkAdvancedSearch(user);

      // Communication
      case Feature.musicRooms:
        return _checkMusicRooms(user);
      case Feature.voiceRooms:
        return _checkVoiceRooms(user);
    }
  }

  // Community Feature Checks
  PermissionResult _checkCreateHood(PermissionUser user) {
    if (user.auraPoints >= 500 && user.accountAgeInDays >= 7) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 500 Aura and 7 days account age',
      requiredAura: 500,
      requiredLevel: 5,
      requiredAccountAge: 7,
    );
  }

  PermissionResult _checkCreateEvent(PermissionUser user) {
    if (user.auraPoints >= 300 && user.accountAgeInDays >= 3) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 300 Aura and 3 days account age',
      requiredAura: 300,
      requiredLevel: 3,
      requiredAccountAge: 3,
    );
  }

  PermissionResult _checkPollCreation(PermissionUser user) {
    if (user.auraPoints >= 100) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 100 Aura',
      requiredAura: 100,
      requiredLevel: 2,
      requiredAccountAge: 1,
    );
  }

  // Media Feature Checks
  PermissionResult _checkViewOnce(PermissionUser user) {
    if (user.auraPoints >= 50) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 50 Aura',
      requiredAura: 50,
      requiredLevel: 1,
      requiredAccountAge: 1,
    );
  }

  PermissionResult _checkViewTwice(PermissionUser user) {
    if (user.auraPoints >= 200) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 200 Aura',
      requiredAura: 200,
      requiredLevel: 2,
      requiredAccountAge: 1,
    );
  }

  PermissionResult _checkViewFiveTimes(PermissionUser user) {
    if (user.auraPoints >= 500) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 500 Aura',
      requiredAura: 500,
      requiredLevel: 5,
      requiredAccountAge: 1,
    );
  }

  PermissionResult _checkTimedMedia(PermissionUser user) {
    if (user.auraPoints >= 500) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 500 Aura',
      requiredAura: 500,
      requiredLevel: 5,
      requiredAccountAge: 1,
    );
  }

  // Customization Checks
  PermissionResult _checkChatThemes(PermissionUser user) {
    if (user.auraPoints >= 250) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 250 Aura',
      requiredAura: 250,
      requiredLevel: 3,
      requiredAccountAge: 1,
    );
  }

  PermissionResult _checkCustomProfileBanner(PermissionUser user) {
    if (user.auraPoints >= 1000) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 1000 Aura',
      requiredAura: 1000,
      requiredLevel: 10,
      requiredAccountAge: 14,
    );
  }

  PermissionResult _checkCustomProfileFrame(PermissionUser user) {
    if (user.auraPoints >= 1500) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 1500 Aura',
      requiredAura: 1500,
      requiredLevel: 15,
      requiredAccountAge: 30,
    );
  }

  PermissionResult _checkHoodCustomization(PermissionUser user) {
    if (user.auraPoints >= 1000 && user.level >= 10) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 1000 Aura and Level 10',
      requiredAura: 1000,
      requiredLevel: 10,
      requiredAccountAge: 14,
    );
  }

  // Moderation Checks
  PermissionResult _checkHoodModeration(PermissionUser user) {
    if (user.isModerator) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires Moderator role',
      requiredAura: 2000,
      requiredLevel: 20,
      requiredAccountAge: 60,
    );
  }

  PermissionResult _checkAIModerator(PermissionUser user) {
    if (user.auraPoints >= 5000 && user.isModerator) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 5000 Aura and Moderator role',
      requiredAura: 5000,
      requiredLevel: 25,
      requiredAccountAge: 90,
    );
  }

  // Special Access Checks
  PermissionResult _checkLeaderboardHallOfFame(PermissionUser user) {
    if (user.auraPoints >= 10000 && user.level >= 50) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 10,000 Aura and Level 50',
      requiredAura: 10000,
      requiredLevel: 50,
      requiredAccountAge: 180,
    );
  }

  PermissionResult _checkOraLabs(PermissionUser user) {
    if (user.hasPremium || user.auraPoints >= 5000) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires Premium or 5000 Aura',
      requiredAura: 5000,
      requiredLevel: 25,
      requiredAccountAge: 30,
    );
  }

  PermissionResult _checkVerifiedCreator(PermissionUser user) {
    if (user.isVerified) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires Verified status',
      requiredAura: 3000,
      requiredLevel: 15,
      requiredAccountAge: 60,
    );
  }

  PermissionResult _checkAdvancedSearch(PermissionUser user) {
    if (user.auraPoints >= 500) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 500 Aura',
      requiredAura: 500,
      requiredLevel: 5,
      requiredAccountAge: 7,
    );
  }

  // Communication Checks
  PermissionResult _checkMusicRooms(PermissionUser user) {
    if (user.auraPoints >= 1000) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 1000 Aura',
      requiredAura: 1000,
      requiredLevel: 10,
      requiredAccountAge: 14,
    );
  }

  PermissionResult _checkVoiceRooms(PermissionUser user) {
    if (user.auraPoints >= 750) {
      return PermissionResult.allowed();
    }
    return PermissionResult.denied(
      reason: 'Requires 750 Aura',
      requiredAura: 750,
      requiredLevel: 8,
      requiredAccountAge: 10,
    );
  }
}