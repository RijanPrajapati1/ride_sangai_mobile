import '../entities/ride_request.dart';

abstract class RideRequestRepository {
  Future<List<RideRequest>> getRequestsForOrganizer(String organizerId);
  Future<void> approve(String requestId);
  Future<void> decline(String requestId);
}
