import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/user_local_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/follow_user.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';

final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSource();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userLocalDataSourceProvider));
});

final profileProvider = FutureProvider.family<UserProfile, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getProfile(userId);
});

final currentUserProfileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(userRepositoryProvider).getProfile(AppConstants.currentUserId);
});

final recommendedRidersProvider = FutureProvider<List<UserProfile>>((ref) {
  return ref.watch(userRepositoryProvider).getRecommendedRiders();
});

final userPreferencesProvider = FutureProvider<UserPreferences>((ref) {
  return ref.watch(userRepositoryProvider).getPreferences();
});

final profileControllerProvider = Provider((ref) => ProfileController(ref));

class ProfileController {
  final Ref _ref;

  ProfileController(this._ref);

  Future<void> toggleFollow(String userId, {required bool isCurrentlyFollowing}) async {
    final useCase = FollowUser(_ref.read(userRepositoryProvider));
    await useCase(userId, isCurrentlyFollowing: isCurrentlyFollowing);
    _ref.invalidate(profileProvider(userId));
    _ref.invalidate(recommendedRidersProvider);
  }

  Future<void> updateProfile(UserProfile profile) async {
    final useCase = UpdateProfile(_ref.read(userRepositoryProvider));
    await useCase(profile);
    _ref.invalidate(profileProvider(profile.id));
    _ref.invalidate(currentUserProfileProvider);
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    await _ref.read(userRepositoryProvider).updatePreferences(preferences);
    _ref.invalidate(userPreferencesProvider);
  }

  Future<UserProfile> fetchProfile(String userId) {
    return GetProfile(_ref.read(userRepositoryProvider))(userId);
  }
}
