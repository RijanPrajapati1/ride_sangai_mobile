import '../../../../core/enums/ride_enums.dart';
import '../entities/ride_request.dart';

abstract class RideRequestRepository {
  /// Join requests across every ride the signed-in rider organizes, newest
  /// first. [organizerId] must be the signed-in rider's id.
  Future<List<RideRequest>> getRequestsForOrganizer(String organizerId, {RideRequestStatus? status});

  /// One ride's join requests (organizer or superadmin).
  Future<List<RideRequest>> getRequestsForRide(String rideId, {RideRequestStatus? status});

  Future<RideRequest> approve(String requestId);

  /// Declines a pending request; [reason] is shared with the rider.
  Future<RideRequest> decline(String requestId, {String? reason});

  /// Superadmin-only: every join request across every ride.
  Future<List<RideRequest>> getAllRequests({RideRequestStatus? status});
}
