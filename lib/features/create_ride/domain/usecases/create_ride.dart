import '../../../../core/enums/ride_enums.dart';
import '../../../rides/domain/entities/ride.dart';
import '../../../rides/domain/repositories/ride_repository.dart';

class CreateRide {
  final RideRepository _repository;

  const CreateRide(this._repository);

  Future<Ride> call({
    required String title,
    required String description,
    required DateTime date,
    required String meetingPoint,
    required RideType rideType,
    required RideDifficulty difficulty,
    required double distanceKm,
    required int durationMinutes,
    required int maxParticipants,
    required List<String> requirements,
    String? imageUrl,
  }) {
    return _repository.createRide(
      title: title,
      description: description,
      date: date,
      meetingPoint: meetingPoint,
      rideType: rideType,
      difficulty: difficulty,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      maxParticipants: maxParticipants,
      requirements: requirements,
      imageUrl: imageUrl,
    );
  }
}
