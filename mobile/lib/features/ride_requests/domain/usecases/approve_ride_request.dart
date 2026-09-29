import '../repositories/ride_request_repository.dart';

class ApproveRideRequest {
  final RideRequestRepository _repository;

  const ApproveRideRequest(this._repository);

  Future<void> call(String requestId) => _repository.approve(requestId);
}
