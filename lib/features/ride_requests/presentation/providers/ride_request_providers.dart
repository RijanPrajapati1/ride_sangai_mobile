import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../rides/presentation/providers/ride_providers.dart';
import '../../data/datasources/ride_request_local_datasource.dart';
import '../../data/repositories/ride_request_repository_impl.dart';
import '../../domain/entities/ride_request.dart';
import '../../domain/repositories/ride_request_repository.dart';
import '../../domain/usecases/approve_ride_request.dart';
import '../../domain/usecases/decline_ride_request.dart';

final rideRequestLocalDataSourceProvider = Provider<RideRequestLocalDataSource>((ref) {
  return RideRequestLocalDataSource();
});

final rideRequestRepositoryProvider = Provider<RideRequestRepository>((ref) {
  return RideRequestRepositoryImpl(ref.watch(rideRequestLocalDataSourceProvider));
});

final organizerRequestsProvider = FutureProvider<List<RideRequest>>((ref) {
  return ref.watch(rideRequestRepositoryProvider).getRequestsForOrganizer(AppConstants.currentUserId);
});

final rideRequestActionsControllerProvider = Provider((ref) => RideRequestActionsController(ref));

class RideRequestActionsController {
  final Ref _ref;

  RideRequestActionsController(this._ref);

  Future<void> approve(String requestId, {required String rideId}) async {
    await ApproveRideRequest(_ref.read(rideRequestRepositoryProvider))(requestId);
    _invalidate(rideId);
  }

  Future<void> decline(String requestId, {required String rideId, String? reason}) async {
    await DeclineRideRequest(_ref.read(rideRequestRepositoryProvider))(requestId, reason: reason);
    _invalidate(rideId);
  }

  void _invalidate(String rideId) {
    _ref.invalidate(organizerRequestsProvider);
    _ref.invalidate(rideDetailsProvider(rideId));
  }
}
