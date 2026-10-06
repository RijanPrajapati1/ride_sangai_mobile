import '../../../../core/enums/ride_enums.dart';
import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/user_profile.dart';

/// Mirrors the API's `UserProfile` schema (also the base of `AdminUser`,
/// whose extra fields are ignored here).
class UserProfileDto {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String bio;
  final String location;
  final ExperienceLevel experienceLevel;
  final RideType preferredRideType;
  final List<String> cyclingInterests;
  final int totalRides;
  final int completedRides;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool isMe;
  final bool isPrivate;
  final bool statsHidden;

  const UserProfileDto({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.bio,
    required this.location,
    required this.experienceLevel,
    required this.preferredRideType,
    required this.cyclingInterests,
    required this.totalRides,
    required this.completedRides,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    required this.isMe,
    required this.isPrivate,
    required this.statsHidden,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) => UserProfileDto(
        id: json['id'] as String,
        name: json['name'] as String,
        // Only sent to the owner and superadmins; null for everyone else.
        email: json['email'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        location: json['location'] as String? ?? '',
        experienceLevel: enumByName(ExperienceLevel.values, json['experienceLevel'], ExperienceLevel.beginner),
        preferredRideType: enumByName(RideType.values, json['preferredRideType'], RideType.road),
        cyclingInterests: stringList(json['cyclingInterests']),
        totalRides: json['totalRides'] as int? ?? 0,
        completedRides: json['completedRides'] as int? ?? 0,
        followersCount: json['followersCount'] as int? ?? 0,
        followingCount: json['followingCount'] as int? ?? 0,
        isFollowing: json['isFollowing'] as bool? ?? false,
        isMe: json['isMe'] as bool? ?? false,
        isPrivate: json['isPrivate'] as bool? ?? false,
        statsHidden: json['statsHidden'] as bool? ?? false,
      );

  /// Body for `PATCH /me`: only the fields a rider may edit. Counters, email
  /// and stats are owned by the server.
  static Map<String, dynamic> toUpdateJson(UserProfile profile) => {
        'name': profile.name.trim(),
        'avatarUrl': profile.avatarUrl,
        'bio': profile.bio.trim(),
        'location': profile.location.trim(),
        'experienceLevel': profile.experienceLevel.name,
        'preferredRideType': profile.preferredRideType.name,
        'cyclingInterests': profile.cyclingInterests,
      };

  UserProfile toEntity() => UserProfile(
        id: id,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        bio: bio,
        location: location,
        experienceLevel: experienceLevel,
        preferredRideType: preferredRideType,
        cyclingInterests: cyclingInterests,
        totalRides: totalRides,
        completedRides: completedRides,
        followersCount: followersCount,
        followingCount: followingCount,
        isFollowing: isFollowing,
        isMe: isMe,
        isPrivate: isPrivate,
        statsHidden: statsHidden,
      );
}
