import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'dashboard_category.dart';

enum RideDifficulty { easy, moderate, hard }

extension RideDifficultyX on RideDifficulty {
  String get label => switch (this) {
        RideDifficulty.easy => 'Easy',
        RideDifficulty.moderate => 'Moderate',
        RideDifficulty.hard => 'Hard',
      };

  Color get color => switch (this) {
        RideDifficulty.easy => AppColors.difficultyEasy,
        RideDifficulty.moderate => AppColors.difficultyModerate,
        RideDifficulty.hard => AppColors.difficultyHard,
      };
}

enum RideType {
  // Cycling
  road,
  mountain,
  gravel,
  touring,
  social,
  hillClimb,
  nightRide,
  // Trekking
  multiDayTrek,
  dayTrek,
  summitTrek,
  // Hiking
  dayHike,
  natureWalk,
  familyHike,
  // Riding (motorbike)
  touringRide,
  offRoadRide,
  trackDay,
}

extension RideTypeX on RideType {
  String get label => switch (this) {
        RideType.road => 'Road',
        RideType.mountain => 'Mountain',
        RideType.gravel => 'Gravel',
        RideType.touring => 'Touring',
        RideType.social => 'Social',
        RideType.hillClimb => 'Hill Climb',
        RideType.nightRide => 'Night Ride',
        RideType.multiDayTrek => 'Multi-day Trek',
        RideType.dayTrek => 'Day Trek',
        RideType.summitTrek => 'Summit Trek',
        RideType.dayHike => 'Day Hike',
        RideType.natureWalk => 'Nature Walk',
        RideType.familyHike => 'Family Hike',
        RideType.touringRide => 'Touring',
        RideType.offRoadRide => 'Off-road',
        RideType.trackDay => 'Track Day',
      };

  IconData get icon => switch (this) {
        RideType.road => Icons.pedal_bike,
        RideType.mountain => Icons.terrain,
        RideType.gravel => Icons.landscape,
        RideType.touring => Icons.map_outlined,
        RideType.social => Icons.groups_outlined,
        RideType.hillClimb => Icons.trending_up,
        RideType.nightRide => Icons.nightlight_outlined,
        RideType.multiDayTrek => Icons.terrain,
        RideType.dayTrek => Icons.hiking,
        RideType.summitTrek => Icons.landscape,
        RideType.dayHike => Icons.hiking,
        RideType.natureWalk => Icons.forest_outlined,
        RideType.familyHike => Icons.groups_outlined,
        RideType.touringRide => Icons.map_outlined,
        RideType.offRoadRide => Icons.terrain,
        RideType.trackDay => Icons.speed,
      };

  /// Which activity dashboard this type belongs to, so filter chips and
  /// dropdowns only ever show options relevant to the active category.
  DashboardCategory get category => switch (this) {
        RideType.road ||
        RideType.mountain ||
        RideType.gravel ||
        RideType.touring ||
        RideType.social ||
        RideType.hillClimb ||
        RideType.nightRide =>
          DashboardCategory.cycling,
        RideType.multiDayTrek || RideType.dayTrek || RideType.summitTrek => DashboardCategory.trekking,
        RideType.dayHike || RideType.natureWalk || RideType.familyHike => DashboardCategory.hiking,
        RideType.touringRide || RideType.offRoadRide || RideType.trackDay => DashboardCategory.riding,
      };
}

extension RideTypesForCategory on DashboardCategory {
  List<RideType> get rideTypes => RideType.values.where((t) => t.category == this).toList();
}

enum RideJoinStatus { none, pending, approved, declined, organizer }

enum RideRequestStatus { pending, approved, declined }

extension RideRequestStatusX on RideRequestStatus {
  String get label => switch (this) {
        RideRequestStatus.pending => 'Pending',
        RideRequestStatus.approved => 'Approved',
        RideRequestStatus.declined => 'Declined',
      };

  Color get color => switch (this) {
        RideRequestStatus.pending => AppColors.warning,
        RideRequestStatus.approved => AppColors.success,
        RideRequestStatus.declined => AppColors.error,
      };
}

enum ExperienceLevel { beginner, intermediate, advanced, pro }

extension ExperienceLevelX on ExperienceLevel {
  String get label => switch (this) {
        ExperienceLevel.beginner => 'Beginner',
        ExperienceLevel.intermediate => 'Intermediate',
        ExperienceLevel.advanced => 'Advanced',
        ExperienceLevel.pro => 'Pro',
      };
}
