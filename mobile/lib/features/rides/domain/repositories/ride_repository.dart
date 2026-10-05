import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/ride_enums.dart';
import '../entities/ride.dart';
import '../entities/ride_participant.dart';

abstract class RideRepository {
  /// Rides that have not started yet, soonest first. Every filter is optional.
  Future<List<Ride>> getUpcomingRides({
    DashboardCategory? category,
    RideType? rideType,
    RideDifficulty? difficulty,
    String? query,
    DateTime? from,
    DateTime? to,
  });
  Future<Ride> getRideById(String id);
  Future<List<RideParticipant>> getParticipants(String rideId);

  /// All rides [organizerId] organizes (any date). Works for any rider.
  Future<List<Ride>> getOrganizedRides(String organizerId);

  /// Future rides the signed-in rider requested or joined. Only available for
  /// the signed-in rider ([userId] must be their id).
  Future<List<Ride>> getJoinedRides(String userId);

  /// Started rides the signed-in rider organized or joined, newest first.
  /// Only available for the signed-in rider.
  Future<List<Ride>> getPastRides(String userId);

  /// Future rides the signed-in rider organizes, joined or requested.
  Future<List<Ride>> getMyUpcomingRides();

  /// Sends a pending join request, with an optional note to the organizer.
  Future<void> requestToJoin(String rideId, {String? message});

  /// Withdraws a pending request, or leaves a ride the rider was approved for.
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

  /// Organizer or admin: changes only the fields that are passed.
  Future<Ride> updateRide(
    String rideId, {
    String? title,
    String? description,
    DateTime? date,
    String? meetingPoint,
    RideType? rideType,
    RideDifficulty? difficulty,
    double? distanceKm,
    int? durationMinutes,
    int? maxParticipants,
    List<String>? requirements,
    String? imageUrl,
  });

  /// Organizer or admin: cancels the ride (riders are notified).
  Future<void> cancelRide(String rideId);

  /// Admin-only: every ride in the system, regardless of date or organizer.
  Future<List<Ride>> getAllRides();

  /// Admin-only: removes a ride from the platform.
  Future<void> deleteRide(String rideId);
}
