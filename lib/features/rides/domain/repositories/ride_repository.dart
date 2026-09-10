import '../../../../core/enums/ride_enums.dart';
import '../entities/ride.dart';
import '../entities/ride_participant.dart';

abstract class RideRepository {
  Future<List<Ride>> getUpcomingRides();
  Future<Ride> getRideById(String id);
  Future<List<RideParticipant>> getParticipants(String rideId);
  Future<List<Ride>> getOrganizedRides(String organizerId);
  Future<List<Ride>> getJoinedRides(String userId);
  Future<List<Ride>> getPastRides(String userId);

  Future<void> requestToJoin(String rideId);
  Future<void> cancelRequest(String rideId);

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
  });

  /// Admin-only: every ride in the system, regardless of date or organizer.
  Future<List<Ride>> getAllRides();

  /// Admin-only: removes a ride from the platform.
  Future<void> deleteRide(String rideId);
}
