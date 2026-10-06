import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/dashboard_category_provider.dart';
import '../../../../core/network/paginated.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/follow_connection.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/follow_user.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(ref.watch(sessionApiClientProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userRemoteDataSourceProvider));
});

final profileProvider = FutureProvider.family<UserProfile, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getProfile(userId);
});

/// The signed-in user's profile (`GET /me`). Re-fetched when the user changes.
final currentUserProfileProvider = FutureProvider<UserProfile>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(userRepositoryProvider).getMyProfile();
});

/// Riders to follow, matching the selected dashboard category first.
final recommendedRidersProvider = FutureProvider<List<UserProfile>>((ref) {
  final category = ref.watch(selectedDashboardCategoryProvider);
  return ref.watch(userRepositoryProvider).getRecommendedRiders(category: category);
});

/// First page of riders whose name matches the query.
final userSearchProvider = FutureProvider.autoDispose.family<Paginated<UserProfile>, String>((ref, query) {
  return ref.watch(userRepositoryProvider).searchUsers(query);
});

final followersProvider = FutureProvider.autoDispose.family<Paginated<FollowConnection>, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getFollowers(userId);
});

final followingProvider = FutureProvider.autoDispose.family<Paginated<FollowConnection>, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getFollowing(userId);
});

final userPreferencesProvider = FutureProvider<UserPreferences>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(userRepositoryProvider).getPreferences();
});

final profileControllerProvider = Provider((ref) => ProfileController(ref));

/// Profile and settings mutations. Each method throws an `AppException` on
/// failure (show its `message`) and refreshes the affected providers.
class ProfileController {
  final Ref _ref;

  ProfileController(this._ref);

  Future<void> toggleFollow(String userId, {required bool isCurrentlyFollowing}) async {
    final useCase = FollowUser(_ref.read(userRepositoryProvider));
    await useCase(userId, isCurrentlyFollowing: isCurrentlyFollowing);
    _ref.invalidate(profileProvider(userId));
    _ref.invalidate(recommendedRidersProvider);
    _ref.invalidate(currentUserProfileProvider);
    _ref.invalidate(followersProvider);
    _ref.invalidate(followingProvider);
  }

  Future<void> updateProfile(UserProfile profile) async {
    final useCase = UpdateProfile(_ref.read(userRepositoryProvider));
    await useCase(profile);
    _ref.invalidate(profileProvider(profile.id));
    _ref.invalidate(currentUserProfileProvider);
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    await _ref.read(userRepositoryProvider).updatePreferences(preferences);
    _afterPreferencesChanged();
  }

  /// Changes only the given toggles (`PATCH /me/preferences`).
  Future<void> setPreferences({
    bool? pushRideReminders,
    bool? pushMessages,
    bool? pushCommunityActivity,
    bool? darkModeEnabled,
    bool? publicProfile,
    bool? showRidingStats,
  }) async {
    await _ref.read(userRepositoryProvider).patchPreferences(
          pushRideReminders: pushRideReminders,
          pushMessages: pushMessages,
          pushCommunityActivity: pushCommunityActivity,
          darkModeEnabled: darkModeEnabled,
          publicProfile: publicProfile,
          showRidingStats: showRidingStats,
        );
    _afterPreferencesChanged();
  }

  /// Deletes the account on the server, then signs out locally.
  Future<void> deleteAccount(String password) async {
    await _ref.read(userRepositoryProvider).deleteAccount(password);
    await _ref.read(authControllerProvider.notifier).logout();
  }

  Future<UserProfile> fetchProfile(String userId) {
    return GetProfile(_ref.read(userRepositoryProvider))(userId);
  }

  void _afterPreferencesChanged() {
    _ref.invalidate(userPreferencesProvider);
    // Privacy toggles change what the profile exposes.
    _ref.invalidate(currentUserProfileProvider);
    _ref.invalidate(profileProvider(_ref.read(currentUserIdProvider)));
  }
}
