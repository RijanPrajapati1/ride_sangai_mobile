import '../../../../core/enums/ride_enums.dart';

class UserProfile {
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

  const UserProfile({
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
    this.isFollowing = false,
  });

  UserProfile copyWith({
    String? name,
    String? bio,
    String? location,
    ExperienceLevel? experienceLevel,
    RideType? preferredRideType,
    List<String>? cyclingInterests,
    int? followersCount,
    bool? isFollowing,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      avatarUrl: avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      preferredRideType: preferredRideType ?? this.preferredRideType,
      cyclingInterests: cyclingInterests ?? this.cyclingInterests,
      totalRides: totalRides,
      completedRides: completedRides,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
