import '../../../../core/constants/app_constants.dart';
import '../../../../core/dummy/dummy_people.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../dto/user_preferences_dto.dart';
import '../dto/user_profile_dto.dart';

class UserLocalDataSource {
  UserLocalDataSource() {
    _profiles = _seedProfiles();
  }

  late final Map<String, UserProfileDto> _profiles;
  UserPreferencesDto _preferences = UserPreferencesDto();

  Future<UserProfileDto> getProfile(String userId) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    final profile = _profiles[userId];
    if (profile == null) throw const NotFoundException('This rider could not be found.');
    return profile;
  }

  Future<UserProfileDto> updateProfile(UserProfileDto profile) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    _profiles[profile.id] = profile;
    return profile;
  }

  Future<void> setFollowing(String userId, bool isFollowing) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final profile = _profiles[userId];
    if (profile == null) return;
    if (profile.isFollowing == isFollowing) return;
    _profiles[userId] = profile.copyWith(
      isFollowing: isFollowing,
      followersCount: profile.followersCount + (isFollowing ? 1 : -1),
    );
  }

  Future<List<UserProfileDto>> getRecommendedRiders() async {
    await Future.delayed(AppConstants.dataSourceDelay);
    return _profiles.values.where((p) => p.id != DummyPeople.me.id && !p.isFollowing).toList();
  }

  Future<UserPreferencesDto> getPreferences() async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    return _preferences;
  }

  Future<UserPreferencesDto> updatePreferences(UserPreferencesDto preferences) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _preferences = preferences;
    return _preferences;
  }

  Map<String, UserProfileDto> _seedProfiles() {
    UserProfileDto build(
      DummyPerson p, {
      required String bio,
      required String location,
      required ExperienceLevel level,
      required RideType preferred,
      required List<String> interests,
      required int totalRides,
      required int completedRides,
      required int followers,
      required int following,
      bool isFollowing = false,
    }) {
      return UserProfileDto(
        id: p.id,
        name: p.name,
        email: '${p.name.split(' ').first.toLowerCase()}@bikersync.app',
        avatarUrl: p.avatarUrl,
        bio: bio,
        location: location,
        experienceLevel: level,
        preferredRideType: preferred,
        cyclingInterests: interests,
        totalRides: totalRides,
        completedRides: completedRides,
        followersCount: followers,
        followingCount: following,
        isFollowing: isFollowing,
      );
    }

    final entries = <UserProfileDto>[
      build(
        DummyPeople.me,
        bio: 'Weekend warrior chasing sunrise rides around the valley. Always up for a hill '
            'climb and a good cup of coffee after.',
        location: 'Kathmandu, Nepal',
        level: ExperienceLevel.intermediate,
        preferred: RideType.road,
        interests: const ['Hill Climbs', 'Road Cycling', 'Photography', 'Coffee Rides'],
        totalRides: 24,
        completedRides: 18,
        followers: 12,
        following: 35,
      ),
      build(
        DummyPeople.aarav,
        bio: 'Organizing sunrise and heritage rides across the valley for six years. '
            'Believer in slow mornings and steady climbs.',
        location: 'Kathmandu, Nepal',
        level: ExperienceLevel.advanced,
        preferred: RideType.social,
        interests: const ['Group Rides', 'Heritage Tours', 'Endurance'],
        totalRides: 142,
        completedRides: 138,
        followers: 486,
        following: 120,
        isFollowing: true,
      ),
      build(
        DummyPeople.priya,
        bio: 'Cultural-loop specialist. If there is a temple on the route, I am leading it.',
        location: 'Bhaktapur, Nepal',
        level: ExperienceLevel.intermediate,
        preferred: RideType.touring,
        interests: const ['Heritage Tours', 'Gravel', 'Trail Photography'],
        totalRides: 63,
        completedRides: 59,
        followers: 210,
        following: 88,
      ),
      build(
        DummyPeople.bibek,
        bio: 'Night owl on two wheels. You will usually find me out after sunset.',
        location: 'Kathmandu, Nepal',
        level: ExperienceLevel.beginner,
        preferred: RideType.nightRide,
        interests: const ['Night Rides', 'City Loops'],
        totalRides: 15,
        completedRides: 12,
        followers: 34,
        following: 51,
      ),
      build(
        DummyPeople.anita,
        bio: 'Trail dog. Pine forests, singletrack, and a thermos of tea at the top.',
        location: 'Budhanilkantha, Nepal',
        level: ExperienceLevel.advanced,
        preferred: RideType.mountain,
        interests: const ['Mountain Biking', 'Trail Running', 'Wildlife'],
        totalRides: 97,
        completedRides: 90,
        followers: 302,
        following: 76,
        isFollowing: true,
      ),
      build(
        DummyPeople.suresh,
        bio: 'Climbing specialist. Nagarkot is basically my backyard at this point.',
        location: 'Bhaktapur, Nepal',
        level: ExperienceLevel.pro,
        preferred: RideType.hillClimb,
        interests: const ['Hill Climbs', 'Endurance', 'Bike Maintenance'],
        totalRides: 211,
        completedRides: 205,
        followers: 640,
        following: 40,
      ),
      build(
        DummyPeople.kabita,
        bio: 'Evening spins, good playlists, and even better company.',
        location: 'Lalitpur, Nepal',
        level: ExperienceLevel.intermediate,
        preferred: RideType.social,
        interests: const ['Social Rides', 'Coffee Rides'],
        totalRides: 41,
        completedRides: 37,
        followers: 158,
        following: 94,
      ),
      build(
        DummyPeople.nischal,
        bio: 'Switchbacks and suffering, then a cable car ride down. Chandragiri regular.',
        location: 'Thankot, Nepal',
        level: ExperienceLevel.advanced,
        preferred: RideType.hillClimb,
        interests: const ['Hill Climbs', 'Gravel'],
        totalRides: 88,
        completedRides: 81,
        followers: 176,
        following: 65,
      ),
      build(
        DummyPeople.roshani,
        bio: 'Gravel over everything. Give me rolling hills and a sunrise.',
        location: 'Banepa, Nepal',
        level: ExperienceLevel.intermediate,
        preferred: RideType.gravel,
        interests: const ['Gravel', 'Bikepacking'],
        totalRides: 54,
        completedRides: 49,
        followers: 122,
        following: 70,
      ),
      build(
        DummyPeople.dipesh,
        bio: 'Mountain bike or nothing. Godavari trails are my playground.',
        location: 'Lalitpur, Nepal',
        level: ExperienceLevel.pro,
        preferred: RideType.mountain,
        interests: const ['Mountain Biking', 'Trail Building'],
        totalRides: 176,
        completedRides: 169,
        followers: 512,
        following: 58,
      ),
      build(
        DummyPeople.sabina,
        bio: 'Slow historical circuits are underrated. Kirtipur every Sunday.',
        location: 'Kirtipur, Nepal',
        level: ExperienceLevel.beginner,
        preferred: RideType.touring,
        interests: const ['Heritage Tours', 'Photography'],
        totalRides: 19,
        completedRides: 16,
        followers: 47,
        following: 63,
      ),
    ];

    return {for (final p in entries) p.id: p};
  }
}
