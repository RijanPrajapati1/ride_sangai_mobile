import '../entities/ride_request.dart';
import '../repositories/ride_request_repository.dart';

class DeclineRideRequest {
  final RideRequestRepository _repository;

  const DeclineRideRequest(this._repository);

  Future<RideRequest> call(String requestId, {String? reason}) => _repository.decline(requestId, reason: reason);
}
