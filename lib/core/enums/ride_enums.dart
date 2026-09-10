import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

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

enum RideType { road, mountain, gravel, touring, social, hillClimb, nightRide }

extension RideTypeX on RideType {
  String get label => switch (this) {
        RideType.road => 'Road',
        RideType.mountain => 'Mountain',
        RideType.gravel => 'Gravel',
        RideType.touring => 'Touring',
        RideType.social => 'Social',
        RideType.hillClimb => 'Hill Climb',
        RideType.nightRide => 'Night Ride',
      };

  IconData get icon => switch (this) {
        RideType.road => Icons.pedal_bike,
        RideType.mountain => Icons.terrain,
        RideType.gravel => Icons.landscape,
        RideType.touring => Icons.map_outlined,
        RideType.social => Icons.groups_outlined,
        RideType.hillClimb => Icons.trending_up,
        RideType.nightRide => Icons.nightlight_outlined,
      };
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
