import '../../domain/entities/user_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';
import '../dto/user_profile_dto.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

  @override
  Future<UserProfile> getProfile(String userId) async {
    final dto = await _dataSource.getProfile(userId);
    return dto.toEntity();
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final dto = UserProfileDto(
      id: profile.id,
      name: profile.name,
      email: profile.email,
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      location: profile.location,
      experienceLevel: profile.experienceLevel,
      preferredRideType: profile.preferredRideType,
      cyclingInterests: profile.cyclingInterests,
      totalRides: profile.totalRides,
      completedRides: profile.completedRides,
      followersCount: profile.followersCount,
      followingCount: profile.followingCount,
      isFollowing: profile.isFollowing,
    );
    final updated = await _dataSource.updateProfile(dto);
    return updated.toEntity();
  }

  @override
  Future<void> followUser(String userId) => _dataSource.setFollowing(userId, true);

  @override
  Future<void> unfollowUser(String userId) => _dataSource.setFollowing(userId, false);

  @override
  Future<List<UserProfile>> getRecommendedRiders() async {
    final dtos = await _dataSource.getRecommendedRiders();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<UserPreferences> getPreferences() async {
    final dto = await _dataSource.getPreferences();
    return dto.toEntity();
  }

  @override
  Future<UserPreferences> updatePreferences(UserPreferences preferences) async {
    final dto = await _dataSource.getPreferences();
    final updatedDto = dto.copyWith(
      pushRideReminders: preferences.pushRideReminders,
      pushMessages: preferences.pushMessages,
      pushCommunityActivity: preferences.pushCommunityActivity,
      darkModeEnabled: preferences.darkModeEnabled,
      publicProfile: preferences.publicProfile,
      showRidingStats: preferences.showRidingStats,
    );
    final saved = await _dataSource.updatePreferences(updatedDto);
    return saved.toEntity();
  }

  @override
  Future<List<UserProfile>> getAllUsers() async {
    final dtos = await _dataSource.getAllUsers();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<void> removeUser(String userId) => _dataSource.removeUser(userId);
}
