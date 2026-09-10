import '../repositories/ride_repository.dart';

class CancelRideRequest {
  final RideRepository _repository;

  const CancelRideRequest(this._repository);

  Future<void> call(String rideId) => _repository.cancelRequest(rideId);
}
