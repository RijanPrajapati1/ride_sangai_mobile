class AppConstants {
  AppConstants._();

  static const String appName = 'Biker Sync';
  static const String appTagline = 'Ride together. Discover more.';

  static const Duration dataSourceDelay = Duration(milliseconds: 550);
  static const Duration shortDataSourceDelay = Duration(milliseconds: 300);

  static const String onboardingCompleteKey = 'onboarding_complete';
  /// v2: reset once so every install starts in light mode; later choices in
  /// Settings are saved here.
  static const String themeModeKey = 'theme_mode_v2';

  /// Demo rider loaded by the server's seed data (`npm run db:seed`), used by
  /// the "Try Demo Login" button.
  static const String demoEmail = 'demo@bikersync.app';
  static const String demoPassword = 'biker123';
}
