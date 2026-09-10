import '../entities/user_profile.dart';
import '../entities/user_preferences.dart';

abstract class UserRepository {
  Future<UserProfile> getProfile(String userId);
  Future<UserProfile> updateProfile(UserProfile profile);
  Future<void> followUser(String userId);
  Future<void> unfollowUser(String userId);
  Future<List<UserProfile>> getRecommendedRiders();
  Future<UserPreferences> getPreferences();
  Future<UserPreferences> updatePreferences(UserPreferences preferences);

  /// Admin-only: every rider registered in the app.
  Future<List<UserProfile>> getAllUsers();

  /// Admin-only: removes a rider from the platform.
  Future<void> removeUser(String userId);
}
