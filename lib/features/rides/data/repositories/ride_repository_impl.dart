import '../../../../core/dummy/dummy_people.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_participant.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/ride_local_datasource.dart';
import '../dto/ride_dto.dart';

class RideRepositoryImpl implements RideRepository {
  final RideLocalDataSource _dataSource;

  RideRepositoryImpl(this._dataSource);

  @override
  Future<List<Ride>> getUpcomingRides() async {
    final dtos = await _dataSource.getUpcomingRides();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Ride> getRideById(String id) async {
    final dto = await _dataSource.getRideById(id);
    return dto.toEntity();
  }

  @override
  Future<List<RideParticipant>> getParticipants(String rideId) async {
    final dtos = await _dataSource.getParticipants(rideId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<Ride>> getOrganizedRides(String organizerId) async {
    final dtos = await _dataSource.getOrganizedRides(organizerId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<Ride>> getJoinedRides(String userId) async {
    final dtos = await _dataSource.getJoinedRides(userId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<Ride>> getPastRides(String userId) async {
    final dtos = await _dataSource.getPastRides(userId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<void> requestToJoin(String rideId) => _dataSource.requestToJoin(rideId);

  @override
  Future<void> cancelRequest(String rideId) => _dataSource.cancelRequest(rideId);

  @override
  Future<Ride> createRide({
    required String title,
    required String description,
    required DateTime date,
    required String meetingPoint,
    required RideType rideType,
    required RideDifficulty difficulty,
    required double distanceKm,
    required int durationMinutes,
    required int maxParticipants,
    required List<String> requirements,
    String? imageUrl,
  }) async {
    final dto = RideDto(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      date: date,
      meetingPoint: meetingPoint,
      rideType: rideType,
      difficulty: difficulty,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      organizerId: DummyPeople.me.id,
      organizerName: DummyPeople.me.name,
      organizerAvatarUrl: DummyPeople.me.avatarUrl,
      imageUrl: imageUrl ?? 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/900/600',
      participantCount: 1,
      maxParticipants: maxParticipants,
      requirements: requirements,
      joinStatus: RideJoinStatus.organizer,
    );
    final created = await _dataSource.createRide(dto);
    return created.toEntity();
  }

  @override
  Future<List<Ride>> getAllRides() async {
    final dtos = await _dataSource.getAllRides();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<void> deleteRide(String rideId) => _dataSource.deleteRide(rideId);
}
