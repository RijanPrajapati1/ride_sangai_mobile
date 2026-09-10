import '../../../../core/constants/app_constants.dart';
import '../../../../core/dummy/dummy_people.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../dto/ride_dto.dart';
import '../dto/ride_participant_dto.dart';

/// In-memory dummy source of truth for rides. A future `RideRemoteDataSource`
/// can implement the same shape backed by a real API or Firebase.
class RideLocalDataSource {
  RideLocalDataSource() {
    _rides = _seedRides();
  }

  late final List<RideDto> _rides;
  final List<RideParticipantDto> _participants = [];

  Future<List<RideDto>> getUpcomingRides() async {
    await Future.delayed(AppConstants.dataSourceDelay);
    final now = DateTime.now();
    return _rides.where((r) => r.date.isAfter(now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<RideDto> getRideById(String id) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final ride = _rides.where((r) => r.id == id).firstOrNull;
    if (ride == null) throw const NotFoundException('This ride no longer exists.');
    return ride;
  }

  Future<List<RideParticipantDto>> getParticipants(String rideId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    return _participants.where((p) => p.rideId == rideId).toList();
  }

  Future<List<RideDto>> getOrganizedRides(String organizerId) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    return _rides.where((r) => r.organizerId == organizerId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<RideDto>> getJoinedRides(String userId) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    final now = DateTime.now();
    return _rides
        .where((r) =>
            r.date.isAfter(now) &&
            (r.joinStatus == RideJoinStatus.approved || r.joinStatus == RideJoinStatus.pending))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<RideDto>> getPastRides(String userId) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    final now = DateTime.now();
    return _rides.where((r) => r.date.isBefore(now)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> requestToJoin(String rideId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) throw const NotFoundException();
    final ride = _rides[index];
    if (ride.organizerId == DummyPeople.me.id) return;
    _rides[index] = ride.copyWith(joinStatus: RideJoinStatus.pending);
  }

  Future<void> cancelRequest(String rideId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) throw const NotFoundException();
    final ride = _rides[index];
    final wasApproved = ride.joinStatus == RideJoinStatus.approved;
    _rides[index] = ride.copyWith(
      joinStatus: RideJoinStatus.none,
      participantCount: wasApproved ? ride.participantCount - 1 : ride.participantCount,
    );
  }

  Future<RideDto> createRide(RideDto dto) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    _rides.insert(0, dto);
    return dto;
  }

  List<RideDto> _seedRides() {
    final now = DateTime.now();
    DateTime at(int daysFromNow, int hour, [int minute = 0]) {
      final d = now.add(Duration(days: daysFromNow));
      return DateTime(d.year, d.month, d.day, hour, minute);
    }

    return [
      RideDto(
        id: 'r_001',
        title: 'Kathmandu Sunrise Ride',
        description:
            'Beat the traffic and greet the sun on a mellow loop through Kathmandu\'s quiet '
            'early-morning streets, finishing with tea at Ratna Park. A great starter ride for '
            'anyone new to group cycling.',
        date: at(2, 5, 30),
        meetingPoint: 'Ratna Park, Kathmandu',
        rideType: RideType.social,
        difficulty: RideDifficulty.easy,
        distanceKm: 18,
        durationMinutes: 75,
        organizerId: DummyPeople.aarav.id,
        organizerName: DummyPeople.aarav.name,
        organizerAvatarUrl: DummyPeople.aarav.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/ktm-sunrise/900/600',
        participantCount: 14,
        maxParticipants: 25,
        requirements: const ['Helmet', 'Front & rear lights', 'Water bottle'],
        participantAvatars: [
          DummyPeople.priya.avatarUrl,
          DummyPeople.bibek.avatarUrl,
          DummyPeople.kabita.avatarUrl,
        ],
      ),
      RideDto(
        id: 'r_002',
        title: 'Bhaktapur Heritage Loop',
        description:
            'A relaxed cultural ride through the medieval alleys and squares of Bhaktapur. '
            'We\'ll stop at Nyatapola Temple and Dattatreya Square for photos before looping back '
            'along the Hanumante River.',
        date: at(4, 7, 0),
        meetingPoint: 'Durbar Square, Bhaktapur',
        rideType: RideType.touring,
        difficulty: RideDifficulty.easy,
        distanceKm: 22,
        durationMinutes: 100,
        organizerId: DummyPeople.priya.id,
        organizerName: DummyPeople.priya.name,
        organizerAvatarUrl: DummyPeople.priya.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/bhaktapur-loop/900/600',
        participantCount: 9,
        maxParticipants: 20,
        requirements: const ['Helmet', 'Comfortable saddle', 'Camera optional'],
        participantAvatars: [DummyPeople.me.avatarUrl, DummyPeople.suresh.avatarUrl],
      ),
      RideDto(
        id: 'r_003',
        title: 'Nagarkot Weekend Climb',
        description:
            'A demanding climb up to Nagarkot for sweeping Himalayan views. Expect steady '
            'gradients for the first 15km and a fast, technical descent back. Strong legs '
            'recommended.',
        date: at(6, 5, 0),
        meetingPoint: 'Bhaktapur Bus Park',
        rideType: RideType.hillClimb,
        difficulty: RideDifficulty.hard,
        distanceKm: 52,
        durationMinutes: 240,
        organizerId: DummyPeople.suresh.id,
        organizerName: DummyPeople.suresh.name,
        organizerAvatarUrl: DummyPeople.suresh.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/nagarkot-climb/900/600',
        participantCount: 21,
        maxParticipants: 30,
        requirements: const ['Road/gravel bike', 'Helmet', 'Spare tube & pump', 'Nutrition for 4h+'],
        participantAvatars: [
          DummyPeople.nischal.avatarUrl,
          DummyPeople.dipesh.avatarUrl,
          DummyPeople.anita.avatarUrl,
          DummyPeople.me.avatarUrl,
        ],
        joinStatus: RideJoinStatus.approved,
      ),
      RideDto(
        id: 'r_004',
        title: 'Lalitpur Evening Spin',
        description:
            'An easygoing after-work spin around Lalitpur\'s ring road, wrapping up with '
            'coffee at Pulchowk. Lights required as we\'ll finish after dusk.',
        date: at(1, 17, 30),
        meetingPoint: 'Patan Durbar Square',
        rideType: RideType.social,
        difficulty: RideDifficulty.easy,
        distanceKm: 15,
        durationMinutes: 60,
        organizerId: DummyPeople.kabita.id,
        organizerName: DummyPeople.kabita.name,
        organizerAvatarUrl: DummyPeople.kabita.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/lalitpur-spin/900/600',
        participantCount: 11,
        maxParticipants: 18,
        requirements: const ['Rear light', 'Reflective vest recommended'],
        participantAvatars: [DummyPeople.roshani.avatarUrl, DummyPeople.sabina.avatarUrl],
        joinStatus: RideJoinStatus.pending,
      ),
      RideDto(
        id: 'r_005',
        title: 'Godavari Hills Challenge',
        description:
            'Singletrack, fire roads, and a punishing final ascent through the Godavari '
            'botanical hills. This is a proper mountain-bike test with technical descents.',
        date: at(9, 6, 0),
        meetingPoint: 'Godavari Botanical Garden Gate',
        rideType: RideType.mountain,
        difficulty: RideDifficulty.hard,
        distanceKm: 34,
        durationMinutes: 210,
        organizerId: DummyPeople.dipesh.id,
        organizerName: DummyPeople.dipesh.name,
        organizerAvatarUrl: DummyPeople.dipesh.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/godavari-hills/900/600',
        participantCount: 8,
        maxParticipants: 15,
        requirements: const ['Full-suspension or hardtail MTB', 'Helmet', 'Knee pads recommended'],
        participantAvatars: [DummyPeople.bibek.avatarUrl],
      ),
      RideDto(
        id: 'r_006',
        title: 'Shivapuri Forest Trail',
        description:
            'Cool pine-forest air and gentle singletrack inside Shivapuri Nagarjun National '
            'Park. A great half-day escape from the city with a packed-lunch stop at the '
            'viewpoint.',
        date: at(12, 6, 30),
        meetingPoint: 'Shivapuri Park Entrance, Sundarijal',
        rideType: RideType.mountain,
        difficulty: RideDifficulty.moderate,
        distanceKm: 28,
        durationMinutes: 180,
        organizerId: DummyPeople.anita.id,
        organizerName: DummyPeople.anita.name,
        organizerAvatarUrl: DummyPeople.anita.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/shivapuri-trail/900/600',
        participantCount: 13,
        maxParticipants: 20,
        requirements: const ['MTB or gravel bike', 'Park entry fee', 'Packed lunch'],
        participantAvatars: [DummyPeople.kabita.avatarUrl, DummyPeople.me.avatarUrl],
      ),
      RideDto(
        id: 'r_007',
        title: 'Chandragiri Hill Climb',
        description:
            'A brutal but rewarding switchback climb to Chandragiri Hills. Cable car ticket '
            'included for anyone who wants to ride up and enjoy a scenic descent instead.',
        date: at(15, 5, 45),
        meetingPoint: 'Thankot Chowk',
        rideType: RideType.hillClimb,
        difficulty: RideDifficulty.hard,
        distanceKm: 24,
        durationMinutes: 150,
        organizerId: DummyPeople.nischal.id,
        organizerName: DummyPeople.nischal.name,
        organizerAvatarUrl: DummyPeople.nischal.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/chandragiri-climb/900/600',
        participantCount: 6,
        maxParticipants: 12,
        requirements: const ['Low gearing recommended', 'Helmet', 'Windbreaker for the descent'],
        participantAvatars: [DummyPeople.priya.avatarUrl],
      ),
      RideDto(
        id: 'r_008',
        title: 'Dhulikhel Sunrise Gravel',
        description:
            'Rolling gravel roads east of the valley with far-reaching mountain views at '
            'sunrise. Mixed surfaces throughout, gravel or MTB tyres recommended.',
        date: at(18, 5, 0),
        meetingPoint: 'Banepa Bus Stand',
        rideType: RideType.gravel,
        difficulty: RideDifficulty.moderate,
        distanceKm: 40,
        durationMinutes: 200,
        organizerId: DummyPeople.roshani.id,
        organizerName: DummyPeople.roshani.name,
        organizerAvatarUrl: DummyPeople.roshani.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/dhulikhel-gravel/900/600',
        participantCount: 10,
        maxParticipants: 16,
        requirements: const ['Gravel/MTB tyres 35mm+', 'Helmet', 'Spare tube'],
        participantAvatars: [DummyPeople.sabina.avatarUrl, DummyPeople.suresh.avatarUrl],
      ),
      RideDto(
        id: 'r_009',
        title: 'Thamel Night Ride',
        description:
            'A fun, low-key night ride through the lit-up streets of Thamel and around '
            'Kathmandu Durbar Square, wrapping up with momos for everyone.',
        date: at(3, 20, 0),
        meetingPoint: 'Thamel Chowk',
        rideType: RideType.nightRide,
        difficulty: RideDifficulty.easy,
        distanceKm: 12,
        durationMinutes: 55,
        organizerId: DummyPeople.bibek.id,
        organizerName: DummyPeople.bibek.name,
        organizerAvatarUrl: DummyPeople.bibek.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/thamel-night/900/600',
        participantCount: 19,
        maxParticipants: 25,
        requirements: const ['Front & rear lights (mandatory)', 'Helmet'],
        participantAvatars: [DummyPeople.me.avatarUrl, DummyPeople.anita.avatarUrl],
      ),
      RideDto(
        id: 'r_010',
        title: 'Kirtipur Heritage Circuit',
        description:
            'A gentle historical circuit through the hilltop town of Kirtipur, taking in '
            'Chilancho Stupa and the old Newari courtyards, with a slow climb up to the '
            'viewpoint at the end.',
        date: at(7, 6, 45),
        meetingPoint: 'Kirtipur Bus Park',
        rideType: RideType.touring,
        difficulty: RideDifficulty.easy,
        distanceKm: 20,
        durationMinutes: 90,
        organizerId: DummyPeople.sabina.id,
        organizerName: DummyPeople.sabina.name,
        organizerAvatarUrl: DummyPeople.sabina.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/kirtipur-circuit/900/600',
        participantCount: 7,
        maxParticipants: 20,
        requirements: const ['Helmet', 'Water bottle'],
        participantAvatars: [DummyPeople.dipesh.avatarUrl],
      ),
      RideDto(
        id: 'r_011',
        title: 'Ring Road Endurance Loop',
        description: 'A full lap of the Kathmandu Ring Road for those training for longer '
            'distances. Two rolling support stops along the way.',
        date: now.subtract(const Duration(days: 5)),
        meetingPoint: 'Koteshwor Chowk',
        rideType: RideType.road,
        difficulty: RideDifficulty.moderate,
        distanceKm: 27,
        durationMinutes: 95,
        organizerId: DummyPeople.me.id,
        organizerName: DummyPeople.me.name,
        organizerAvatarUrl: DummyPeople.me.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/ring-road-loop/900/600',
        participantCount: 16,
        maxParticipants: 20,
        requirements: const ['Helmet', 'Water bottle'],
        participantAvatars: [DummyPeople.priya.avatarUrl, DummyPeople.kabita.avatarUrl],
        joinStatus: RideJoinStatus.organizer,
      ),
      RideDto(
        id: 'r_012',
        title: 'Budhanilkantha Foothill Ride',
        description: 'A friendly climb toward Budhanilkantha with a stop at the reclining '
            'Vishnu statue before rolling back downhill.',
        date: now.subtract(const Duration(days: 12)),
        meetingPoint: 'Narayanthan Chowk',
        rideType: RideType.road,
        difficulty: RideDifficulty.moderate,
        distanceKm: 19,
        durationMinutes: 80,
        organizerId: DummyPeople.aarav.id,
        organizerName: DummyPeople.aarav.name,
        organizerAvatarUrl: DummyPeople.aarav.avatarUrl,
        imageUrl: 'https://picsum.photos/seed/budhanilkantha/900/600',
        participantCount: 12,
        maxParticipants: 20,
        requirements: const ['Helmet'],
        participantAvatars: [DummyPeople.me.avatarUrl],
        joinStatus: RideJoinStatus.approved,
      ),
    ];
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
