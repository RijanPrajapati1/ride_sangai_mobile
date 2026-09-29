import '../entities/ride.dart';
import '../repositories/ride_repository.dart';

class GetRideDetails {
  final RideRepository _repository;

  const GetRideDetails(this._repository);

  Future<Ride> call(String rideId) => _repository.getRideById(rideId);
}
