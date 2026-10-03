import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/ride_enums.dart';
import '../../../rides/domain/entities/ride.dart';
import '../../../rides/presentation/providers/ride_providers.dart';
import '../../domain/usecases/create_ride.dart';

final createRideControllerProvider = Provider((ref) => CreateRideController(ref));

class CreateRideController {
  final Ref _ref;

  CreateRideController(this._ref);

  Future<Ride> submit({
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
  }) async {
    final ride = await CreateRide(_ref.read(rideRepositoryProvider))(
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
    _ref.invalidate(upcomingRidesProvider);
    _ref.invalidate(organizedRidesProvider);
    return ride;
  }
}
