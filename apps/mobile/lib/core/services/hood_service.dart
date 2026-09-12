import 'package:mobile/core/models/hood.dart';

class HoodService {
  // TODO: Implement hood logic
  // - Get featured hoods
  // - Get user's hoods
  // - Join/leave hood
  // - Get hood details
  // - Get hood posts
  // - Get hood members
  
  Future<List<HoodModel>> getFeaturedHoods() async {
    throw UnimplementedError('HoodService.getFeaturedHoods not implemented');
  }
  
  Future<List<HoodModel>> getUserHoods() async {
    throw UnimplementedError('HoodService.getUserHoods not implemented');
  }
  
  Future<void> joinHood(String hoodId) async {
    throw UnimplementedError('HoodService.joinHood not implemented');
  }
  
  Future<void> leaveHood(String hoodId) async {
    throw UnimplementedError('HoodService.leaveHood not implemented');
  }
}