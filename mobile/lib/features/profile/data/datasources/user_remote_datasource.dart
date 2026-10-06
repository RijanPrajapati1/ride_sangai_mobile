import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated.dart';
import '../dto/follow_dto.dart';
import '../dto/user_preferences_dto.dart';
import '../dto/user_profile_dto.dart';

/// Calls the `/me`, `/users` and `/superadmin/users` endpoints. Only knows about
/// HTTP and JSON; mapping to domain entities is the repository's job.
class UserRemoteDataSource {
  static const me = '/me';
  static const myPreferences = '/me/preferences';
  static const users = '/users';
  static const recommendedUsers = '/users/recommended';
  static String user(String id) => '/users/$id';
  static String follow(String id) => '/users/$id/follow';
  static String followers(String id) => '/users/$id/followers';
  static String following(String id) => '/users/$id/following';
  static const superadminUsers = '/superadmin/users';
  static String superadminUser(String id) => '/superadmin/users/$id';

  final ApiClient _api;

  UserRemoteDataSource(this._api);

  // --- Me --------------------------------------------------------------------

  Future<UserProfileDto> getMe() async {
    final json = await _api.get<Map<String, dynamic>>(me);
    return UserProfileDto.fromJson(json);
  }

  /// Sends only the editable fields (see [UserProfileDto.toUpdateJson]).
  Future<UserProfileDto> updateMe(Map<String, dynamic> changes) async {
    final json = await _api.patch<Map<String, dynamic>>(me, data: changes);
    return UserProfileDto.fromJson(json);
  }

  /// Permanently deletes the signed-in account. Needs the current password.
  Future<void> deleteMe(String password) => _api.delete<dynamic>(me, data: {'password': password});

  // --- Preferences -----------------------------------------------------------

  Future<UserPreferencesDto> getPreferences() async {
    final json = await _api.get<Map<String, dynamic>>(myPreferences);
    return UserPreferencesDto.fromJson(json);
  }

  Future<UserPreferencesDto> replacePreferences(UserPreferencesDto preferences) async {
    final json = await _api.put<Map<String, dynamic>>(myPreferences, data: preferences.toJson());
    return UserPreferencesDto.fromJson(json);
  }

  /// Changes only the given toggles, so two quick toggles can't overwrite
  /// each other.
  Future<UserPreferencesDto> patchPreferences(Map<String, bool> changes) async {
    final json = await _api.patch<Map<String, dynamic>>(myPreferences, data: changes);
    return UserPreferencesDto.fromJson(json);
  }

  // --- Riders ----------------------------------------------------------------

  Future<Paginated<UserProfileDto>> searchUsers({String? query, String? cursor, int? limit}) async {
    final json = await _api.get<Map<String, dynamic>>(
      users,
      query: {'q': query, 'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, UserProfileDto.fromJson);
  }

  /// [category] is an activity category name (`cycling`, `trekking`, …).
  Future<List<UserProfileDto>> getRecommended({String? category, int? limit}) async {
    final json = await _api.get<Map<String, dynamic>>(
      recommendedUsers,
      query: {'category': category, 'limit': limit},
    );
    return (json['items'] as List).map((item) => UserProfileDto.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<UserProfileDto> getUser(String id) async {
    final json = await _api.get<Map<String, dynamic>>(user(id));
    return UserProfileDto.fromJson(json);
  }

  Future<FollowStateDto> followUser(String id) async {
    final json = await _api.put<Map<String, dynamic>>(follow(id));
    return FollowStateDto.fromJson(json);
  }

  Future<FollowStateDto> unfollowUser(String id) async {
    final json = await _api.delete<Map<String, dynamic>>(follow(id));
    return FollowStateDto.fromJson(json);
  }

  Future<Paginated<FollowEdgeDto>> getFollowers(String id, {String? cursor, int? limit}) async {
    final json = await _api.get<Map<String, dynamic>>(followers(id), query: {'cursor': cursor, 'limit': limit});
    return Paginated.fromJson(json, FollowEdgeDto.fromJson);
  }

  Future<Paginated<FollowEdgeDto>> getFollowing(String id, {String? cursor, int? limit}) async {
    final json = await _api.get<Map<String, dynamic>>(following(id), query: {'cursor': cursor, 'limit': limit});
    return Paginated.fromJson(json, FollowEdgeDto.fromJson);
  }

  // --- Superadmin ------------------------------------------------------------

  /// Superadmin only. [role] is `user` or `superadmin`.
  Future<Paginated<UserProfileDto>> getSuperadminUsers({String? query, String? role, String? cursor, int? limit}) async {
    final json = await _api.get<Map<String, dynamic>>(
      superadminUsers,
      query: {'q': query, 'role': role, 'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, UserProfileDto.fromJson);
  }

  /// Superadmin only. Removes a rider and everything they own.
  Future<void> removeUser(String id) => _api.delete<dynamic>(superadminUser(id));
}
