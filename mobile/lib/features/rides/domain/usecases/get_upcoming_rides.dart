import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/ride_enums.dart';
import '../entities/ride.dart';
import '../repositories/ride_repository.dart';

class GetUpcomingRides {
  final RideRepository _repository;

  const GetUpcomingRides(this._repository);

  Future<List<Ride>> call({
    DashboardCategory? category,
    RideType? rideType,
    RideDifficulty? difficulty,
    String? query,
  }) =>
      _repository.getUpcomingRides(category: category, rideType: rideType, difficulty: difficulty, query: query);
}
