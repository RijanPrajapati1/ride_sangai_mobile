import '../repositories/ride_repository.dart';

class RequestToJoinRide {
  final RideRepository _repository;

  const RequestToJoinRide(this._repository);

  Future<void> call(String rideId, {String? message}) => _repository.requestToJoin(rideId, message: message);
}
