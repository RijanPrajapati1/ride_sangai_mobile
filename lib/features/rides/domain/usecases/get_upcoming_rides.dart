import '../entities/ride.dart';
import '../repositories/ride_repository.dart';

class GetUpcomingRides {
  final RideRepository _repository;

  const GetUpcomingRides(this._repository);

  Future<List<Ride>> call() => _repository.getUpcomingRides();
}
