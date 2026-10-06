import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/network/paginated.dart';
import '../entities/follow_connection.dart';
import '../entities/user_preferences.dart';
import '../entities/user_profile.dart';

abstract class UserRepository {
  /// The signed-in user's own profile.
  Future<UserProfile> getMyProfile();
  Future<UserProfile> getProfile(String userId);

  /// Saves the editable fields of the signed-in user's profile.
  Future<UserProfile> updateProfile(UserProfile profile);

  /// Permanently deletes the signed-in user's account.
  Future<void> deleteAccount(String password);

  Future<void> followUser(String userId);
  Future<void> unfollowUser(String userId);

  /// Riders to follow, matching [category] first when given.
  Future<List<UserProfile>> getRecommendedRiders({DashboardCategory? category});

  /// Riders whose name matches [query].
  Future<Paginated<UserProfile>> searchUsers(String query, {String? cursor});
  Future<Paginated<FollowConnection>> getFollowers(String userId, {String? cursor});
  Future<Paginated<FollowConnection>> getFollowing(String userId, {String? cursor});

  Future<UserPreferences> getPreferences();

  /// Replaces every toggle.
  Future<UserPreferences> updatePreferences(UserPreferences preferences);

  /// Changes only the toggles that are given.
  Future<UserPreferences> patchPreferences({
    bool? pushRideReminders,
    bool? pushMessages,
    bool? pushCommunityActivity,
    bool? darkModeEnabled,
    bool? publicProfile,
    bool? showRidingStats,
  });

  /// Superadmin-only: every rider registered in the app.
  Future<List<UserProfile>> getAllUsers();

  /// Superadmin-only: removes a rider from the platform.
  Future<void> removeUser(String userId);
}
