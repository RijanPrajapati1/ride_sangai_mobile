import '../../domain/entities/user_preferences.dart';

/// Mirrors the API's `UserPreferences` schema.
class UserPreferencesDto {
  final bool pushRideReminders;
  final bool pushMessages;
  final bool pushCommunityActivity;
  final bool darkModeEnabled;
  final bool publicProfile;
  final bool showRidingStats;

  const UserPreferencesDto({
    required this.pushRideReminders,
    required this.pushMessages,
    required this.pushCommunityActivity,
    required this.darkModeEnabled,
    required this.publicProfile,
    required this.showRidingStats,
  });

  factory UserPreferencesDto.fromJson(Map<String, dynamic> json) => UserPreferencesDto(
        pushRideReminders: json['pushRideReminders'] as bool,
        pushMessages: json['pushMessages'] as bool,
        pushCommunityActivity: json['pushCommunityActivity'] as bool,
        darkModeEnabled: json['darkModeEnabled'] as bool,
        publicProfile: json['publicProfile'] as bool,
        showRidingStats: json['showRidingStats'] as bool,
      );

  factory UserPreferencesDto.fromEntity(UserPreferences p) => UserPreferencesDto(
        pushRideReminders: p.pushRideReminders,
        pushMessages: p.pushMessages,
        pushCommunityActivity: p.pushCommunityActivity,
        darkModeEnabled: p.darkModeEnabled,
        publicProfile: p.publicProfile,
        showRidingStats: p.showRidingStats,
      );

  Map<String, dynamic> toJson() => {
        'pushRideReminders': pushRideReminders,
        'pushMessages': pushMessages,
        'pushCommunityActivity': pushCommunityActivity,
        'darkModeEnabled': darkModeEnabled,
        'publicProfile': publicProfile,
        'showRidingStats': showRidingStats,
      };

  UserPreferences toEntity() => UserPreferences(
        pushRideReminders: pushRideReminders,
        pushMessages: pushMessages,
        pushCommunityActivity: pushCommunityActivity,
        darkModeEnabled: darkModeEnabled,
        publicProfile: publicProfile,
        showRidingStats: showRidingStats,
      );
}
