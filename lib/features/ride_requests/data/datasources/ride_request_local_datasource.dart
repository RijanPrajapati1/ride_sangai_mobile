import '../../../../core/constants/app_constants.dart';
import '../../../../core/dummy/dummy_people.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../dto/ride_request_dto.dart';

class RideRequestLocalDataSource {
  RideRequestLocalDataSource() {
    _requests = _seedRequests();
  }

  late final List<RideRequestDto> _requests;

  Future<List<RideRequestDto>> getRequestsForOrganizer(String organizerId) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    return _requests.where((r) => r.rideId == 'r_011' && organizerId == DummyPeople.me.id).toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  Future<void> approve(String requestId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _update(requestId, RideRequestStatus.approved);
  }

  Future<void> decline(String requestId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _update(requestId, RideRequestStatus.declined);
  }

  void _update(String requestId, RideRequestStatus status) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw const NotFoundException('This request no longer exists.');
    _requests[index] = _requests[index].copyWith(status: status);
  }

  List<RideRequestDto> _seedRequests() {
    final now = DateTime.now();
    RideRequestDto build(
      String id,
      DummyPerson p,
      String bio,
      ExperienceLevel level,
      int hoursAgo,
      RideRequestStatus status,
    ) {
      return RideRequestDto(
        id: id,
        rideId: 'r_011',
        rideTitle: 'Ring Road Endurance Loop',
        userId: p.id,
        userName: p.name,
        userAvatarUrl: p.avatarUrl,
        userBio: bio,
        experienceLevel: level,
        requestedAt: now.subtract(Duration(hours: hoursAgo)),
        status: status,
      );
    }

    return [
      build(
        'rq_001',
        DummyPeople.roshani,
        'Training for my first century ride, always looking for group support.',
        ExperienceLevel.intermediate,
        3,
        RideRequestStatus.pending,
      ),
      build(
        'rq_002',
        DummyPeople.nischal,
        'Ridden the ring road a dozen times, happy to help pace the group.',
        ExperienceLevel.advanced,
        6,
        RideRequestStatus.pending,
      ),
      build(
        'rq_003',
        DummyPeople.sabina,
        'New to endurance rides but comfortable on the bike, excited to join!',
        ExperienceLevel.beginner,
        20,
        RideRequestStatus.pending,
      ),
      build(
        'rq_004',
        DummyPeople.dipesh,
        'Usually on MTB trails but want to build road endurance for a race.',
        ExperienceLevel.pro,
        30,
        RideRequestStatus.approved,
      ),
      build(
        'rq_005',
        DummyPeople.bibek,
        'Only free in the evenings, might have to leave the group early.',
        ExperienceLevel.beginner,
        50,
        RideRequestStatus.declined,
      ),
    ];
  }
}
