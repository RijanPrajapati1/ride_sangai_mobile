import '../repositories/ride_request_repository.dart';

class DeclineRideRequest {
  final RideRequestRepository _repository;

  const DeclineRideRequest(this._repository);

  Future<void> call(String requestId) => _repository.decline(requestId);
}
