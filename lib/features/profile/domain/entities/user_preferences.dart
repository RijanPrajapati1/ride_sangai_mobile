class UserPreferences {
  final bool pushRideReminders;
  final bool pushMessages;
  final bool pushCommunityActivity;
  final bool darkModeEnabled;
  final bool publicProfile;
  final bool showRidingStats;

  const UserPreferences({
    this.pushRideReminders = true,
    this.pushMessages = true,
    this.pushCommunityActivity = true,
    this.darkModeEnabled = false,
    this.publicProfile = true,
    this.showRidingStats = true,
  });

  UserPreferences copyWith({
    bool? pushRideReminders,
    bool? pushMessages,
    bool? pushCommunityActivity,
    bool? darkModeEnabled,
    bool? publicProfile,
    bool? showRidingStats,
  }) {
    return UserPreferences(
      pushRideReminders: pushRideReminders ?? this.pushRideReminders,
      pushMessages: pushMessages ?? this.pushMessages,
      pushCommunityActivity: pushCommunityActivity ?? this.pushCommunityActivity,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      publicProfile: publicProfile ?? this.publicProfile,
      showRidingStats: showRidingStats ?? this.showRidingStats,
    );
  }
}
