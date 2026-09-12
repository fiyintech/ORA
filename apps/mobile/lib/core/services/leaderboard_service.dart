import 'package:mobile/core/models/leaderboard_entry.dart';

class LeaderboardService {
  // TODO: Implement leaderboard logic
  // - Get global leaderboard
  // - Get country leaderboard
  // - Get city leaderboard
  // - Get hoods leaderboard
  // - Get friends leaderboard
  // - Get hall of fame
  
  Future<List<LeaderboardEntryModel>> getGlobalLeaderboard() async {
    throw UnimplementedError('LeaderboardService.getGlobalLeaderboard not implemented');
  }
  
  Future<List<LeaderboardEntryModel>> getCountryLeaderboard() async {
    throw UnimplementedError('LeaderboardService.getCountryLeaderboard not implemented');
  }
  
  Future<List<LeaderboardEntryModel>> getCityLeaderboard() async {
    throw UnimplementedError('LeaderboardService.getCityLeaderboard not implemented');
  }
  
  Future<List<LeaderboardEntryModel>> getHoodsLeaderboard() async {
    throw UnimplementedError('LeaderboardService.getHoodsLeaderboard not implemented');
  }
  
  Future<List<LeaderboardEntryModel>> getFriendsLeaderboard() async {
    throw UnimplementedError('LeaderboardService.getFriendsLeaderboard not implemented');
  }
}