import 'package:mobile/core/models/achievement.dart';

class AuraService {
  // TODO: Implement aura logic
  // - Get user aura points
  // - Get steeze level
  // - Award aura points
  // - Get achievements
  // - Get aura history
  // - Calculate progression
  
  Future<int> getAuraPoints(String userId) async {
    throw UnimplementedError('AuraService.getAuraPoints not implemented');
  }
  
  Future<int> getSteezeLevel(String userId) async {
    throw UnimplementedError('AuraService.getSteezeLevel not implemented');
  }
  
  Future<void> awardAura(String userId, String action, int amount) async {
    throw UnimplementedError('AuraService.awardAura not implemented');
  }
  
  Future<List<AchievementModel>> getAchievements(String userId) async {
    throw UnimplementedError('AuraService.getAchievements not implemented');
  }
}