// ORA Permission Engine - Riverpod Provider
//
// Provides global access to the PermissionEngine through Riverpod.
// This allows any widget in the app to check feature permissions.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feature.dart';
import 'permission_engine.dart';
import 'permission_result.dart';

/// Provider for the PermissionEngine singleton
///
/// Usage:
/// ```dart
/// final permissionEngine = ref.read(permissionEngineProvider);
/// final result = permissionEngine.canUseFeature(Feature.createHood, user);
/// ```
final permissionEngineProvider = Provider<PermissionEngine>((ref) {
  return PermissionEngine();
});

/// Example of how to create a user-specific permission checker provider
///
/// This would typically be used with a user provider:
/// ```dart
/// final user = ref.watch(currentUserProvider);
/// final canCreateHood = ref.watch(permissionCheckerProvider(Feature.createHood));
/// ```
final permissionCheckerProvider = Provider.family<PermissionResult, Feature>((ref, feature) {
  // This is a placeholder - in production, you would get the current user
  // from a user provider and pass it to the engine
  // For now, this returns a denied result by default
  return PermissionResult.denied(
    reason: 'User not provided',
    requiredAura: 0,
    requiredLevel: 1,
    requiredAccountAge: 0,
  );
});

/// Documentation for Future Integration
///
/// The PermissionEngine is designed to be extended by future systems:
///
/// 1. Aura Engine Integration:
///    - The Aura Engine should provide current Aura points and Level
///    - These values are passed to PermissionUser when checking permissions
///    - Example: user.auraPoints = await auraEngine.getCurrentAura(userId)
///
/// 2. Achievements Integration:
///    - Achievements can unlock special permissions
///    - Add achievement checks in the permission methods
///    - Example: if (user.unlockedAchievements.contains('premium_access')) return allowed
///
/// 3. Premium/Subscription Integration:
///    - Premium users can have special permissions
///    - Check user.hasPremium in permission methods
///    - Example: if (user.hasPremium) return allowed
///
/// 4. Verification System Integration:
///    - Verified users can access verified-only features
///    - Check user.isVerified in permission methods
///    - Example: if (user.isVerified) return allowed
///
/// 5. Moderator System Integration:
///    - Moderators can access moderation features
///    - Check user.isModerator in permission methods
///    - Example: if (user.isModerator) return allowed
///
/// To integrate these systems:
/// 1. Update PermissionUser to include additional fields as needed
/// 2. Update the permission check methods to include new logic
/// 3. All rules remain centralized in PermissionEngine
/// 4. UI can check permissions using the provider