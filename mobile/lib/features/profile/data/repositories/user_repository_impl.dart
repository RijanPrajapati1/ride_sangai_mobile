import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/network/paginated.dart';
import '../../domain/entities/follow_connection.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';
import '../dto/user_preferences_dto.dart';
import '../dto/user_profile_dto.dart';

class UserRepositoryImpl implements UserRepository {
  /// Page size used when the admin list is loaded in full.
  static const _adminPageSize = 100;

  final UserRemoteDataSource _remote;

  UserRepositoryImpl(this._remote);

  @override
  Future<UserProfile> getMyProfile() async => (await _remote.getMe()).toEntity();

  @override
  Future<UserProfile> getProfile(String userId) async => (await _remote.getUser(userId)).toEntity();

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final updated = await _remote.updateMe(UserProfileDto.toUpdateJson(profile));
    return updated.toEntity();
  }

  @override
  Future<void> deleteAccount(String password) => _remote.deleteMe(password);

  @override
  Future<void> followUser(String userId) => _remote.followUser(userId);

  @override
  Future<void> unfollowUser(String userId) => _remote.unfollowUser(userId);

  @override
  Future<List<UserProfile>> getRecommendedRiders({DashboardCategory? category}) async {
    final dtos = await _remote.getRecommended(category: category?.name);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Paginated<UserProfile>> searchUsers(String query, {String? cursor}) async {
    final page = await _remote.searchUsers(query: query.trim().isEmpty ? null : query.trim(), cursor: cursor);
    return Paginated(items: page.items.map((d) => d.toEntity()).toList(), nextCursor: page.nextCursor);
  }

  @override
  Future<Paginated<FollowConnection>> getFollowers(String userId, {String? cursor}) async {
    final page = await _remote.getFollowers(userId, cursor: cursor);
    return Paginated(items: page.items.map((d) => d.toEntity()).toList(), nextCursor: page.nextCursor);
  }

  @override
  Future<Paginated<FollowConnection>> getFollowing(String userId, {String? cursor}) async {
    final page = await _remote.getFollowing(userId, cursor: cursor);
    return Paginated(items: page.items.map((d) => d.toEntity()).toList(), nextCursor: page.nextCursor);
  }

  @override
  Future<UserPreferences> getPreferences() async => (await _remote.getPreferences()).toEntity();

  @override
  Future<UserPreferences> updatePreferences(UserPreferences preferences) async {
    final saved = await _remote.replacePreferences(UserPreferencesDto.fromEntity(preferences));
    return saved.toEntity();
  }

  @override
  Future<UserPreferences> patchPreferences({
    bool? pushRideReminders,
    bool? pushMessages,
    bool? pushCommunityActivity,
    bool? darkModeEnabled,
    bool? publicProfile,
    bool? showRidingStats,
  }) async {
    final changes = <String, bool>{
      'pushRideReminders': ?pushRideReminders,
      'pushMessages': ?pushMessages,
      'pushCommunityActivity': ?pushCommunityActivity,
      'darkModeEnabled': ?darkModeEnabled,
      'publicProfile': ?publicProfile,
      'showRidingStats': ?showRidingStats,
    };
    if (changes.isEmpty) return getPreferences();
    return (await _remote.patchPreferences(changes)).toEntity();
  }

  /// Loads every page of `GET /admin/users` (alphabetical).
  @override
  Future<List<UserProfile>> getAllUsers() async {
    final users = <UserProfile>[];
    String? cursor;
    do {
      final page = await _remote.getAdminUsers(cursor: cursor, limit: _adminPageSize);
      users.addAll(page.items.map((d) => d.toEntity()));
      cursor = page.nextCursor;
    } while (cursor != null);
    return users;
  }

  @override
  Future<void> removeUser(String userId) => _remote.removeUser(userId);
}
