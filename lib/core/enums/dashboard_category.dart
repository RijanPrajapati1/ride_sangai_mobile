import 'package:flutter/material.dart';

enum DashboardCategory { cycling, trekking, hiking, riding }

extension DashboardCategoryX on DashboardCategory {
  String get label => switch (this) {
        DashboardCategory.cycling => 'Cycling',
        DashboardCategory.trekking => 'Trekking',
        DashboardCategory.hiking => 'Hiking',
        DashboardCategory.riding => 'Riding',
      };

  String get tagline => switch (this) {
        DashboardCategory.cycling => 'Discover and join group bike rides near you.',
        DashboardCategory.trekking => 'Multi-day trekking adventures with a local crew.',
        DashboardCategory.hiking => 'Day hikes and trail meetups in your area.',
        DashboardCategory.riding => 'Motorbike meetups and group rides.',
      };

  IconData get icon => switch (this) {
        DashboardCategory.cycling => Icons.pedal_bike,
        DashboardCategory.trekking => Icons.terrain,
        DashboardCategory.hiking => Icons.hiking,
        DashboardCategory.riding => Icons.two_wheeler,
      };

  /// Noun used for the activity-list bottom nav tab (e.g. "Rides", "Hikes").
  String get activityNoun => switch (this) {
        DashboardCategory.cycling => 'Rides',
        DashboardCategory.trekking => 'Treks',
        DashboardCategory.hiking => 'Hikes',
        DashboardCategory.riding => 'Rides',
      };

  /// Singular form, e.g. "Create a Trek", "Featured Hike".
  String get activitySingular => switch (this) {
        DashboardCategory.cycling => 'Ride',
        DashboardCategory.trekking => 'Trek',
        DashboardCategory.hiking => 'Hike',
        DashboardCategory.riding => 'Ride',
      };
}
