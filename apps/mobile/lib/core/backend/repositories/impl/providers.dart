import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/backend/repositories/post_repository.dart';
import 'package:mobile/core/backend/repositories/follow_repository.dart';
import 'package:mobile/core/backend/repositories/impl/profile_repository_impl.dart';
import 'package:mobile/core/backend/repositories/impl/hood_repository_impl.dart';
import 'package:mobile/core/backend/repositories/impl/leaderboard_repository_impl.dart';
import 'package:mobile/core/backend/repositories/impl/aura_repository_impl.dart';
import 'package:mobile/core/backend/repositories/impl/user_repository_impl.dart';
import 'package:mobile/core/backend/repositories/impl/post_repository_impl.dart';
import 'package:mobile/core/backend/repositories/impl/notification_repository_impl.dart';
import 'package:mobile/core/backend/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl();
});

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository();
});

final profileRepositoryProvider = Provider<ProfileRepositoryImpl>((ref) {
  return ProfileRepositoryImpl();
});

final hoodRepositoryProvider = Provider<HoodRepositoryImpl>((ref) {
  return HoodRepositoryImpl();
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepositoryImpl>((ref) {
  return LeaderboardRepositoryImpl();
});

final auraRepositoryProvider = Provider<AuraRepositoryImpl>((ref) {
  return AuraRepositoryImpl();
});

final notificationRepositoryProvider = Provider<NotificationRepositoryImpl>((ref) {
  return NotificationRepositoryImpl();
});
