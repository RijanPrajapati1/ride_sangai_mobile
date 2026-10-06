class AppConstants {
  AppConstants._();

  static const String appName = 'Biker Sync';
  static const String appTagline = 'Ride together. Discover more.';

  static const String onboardingCompleteKey = 'onboarding_complete';
  /// v2: reset once so every install starts in light mode; later choices in
  /// Settings are saved here.
  static const String themeModeKey = 'theme_mode_v2';

  /// Sent with feedback so reports can be traced to a build. Keep in sync
  /// with `version:` in `pubspec.yaml`.
  static const String appVersion = '1.0.0+1';
}
