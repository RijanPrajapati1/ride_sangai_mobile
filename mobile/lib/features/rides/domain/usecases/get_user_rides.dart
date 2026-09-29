import '../entities/ride.dart';
import '../repositories/ride_repository.dart';

class GetUserRides {
  final RideRepository _repository;

  const GetUserRides(this._repository);

  Future<List<Ride>> organized(String userId) => _repository.getOrganizedRides(userId);

  Future<List<Ride>> joined(String userId) => _repository.getJoinedRides(userId);

  Future<List<Ride>> past(String userId) => _repository.getPastRides(userId);
}
