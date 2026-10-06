import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../rides/presentation/providers/ride_providers.dart';
import '../../data/datasources/ride_request_remote_datasource.dart';
import '../../data/repositories/ride_request_repository_impl.dart';
import '../../domain/entities/ride_request.dart';
import '../../domain/repositories/ride_request_repository.dart';
import '../../domain/usecases/approve_ride_request.dart';
import '../../domain/usecases/decline_ride_request.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';

final rideRequestRemoteDataSourceProvider = Provider<RideRequestRemoteDataSource>((ref) {
  return RideRequestRemoteDataSource(ref.watch(apiClientProvider));
});

final rideRequestRepositoryProvider = Provider<RideRequestRepository>((ref) {
  return RideRequestRepositoryImpl(
    ref.watch(rideRequestRemoteDataSourceProvider),
    () => ref.read(currentUserIdProvider),
  );
});

/// Join requests across every ride the signed-in rider organizes.
final organizerRequestsProvider = FutureProvider<List<RideRequest>>((ref) {
  return ref.watch(rideRequestRepositoryProvider).getRequestsForOrganizer(ref.watch(currentUserIdProvider));
});

/// One ride's join requests (all statuses), for the organizer's Manage
/// Requests screen.
final rideRequestsForRideProvider = FutureProvider.family<List<RideRequest>, String>((ref, rideId) {
  return ref.watch(rideRequestRepositoryProvider).getRequestsForRide(rideId);
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
    _ref.invalidate(rideRequestsForRideProvider(rideId));
    _ref.invalidate(rideDetailsProvider(rideId));
    _ref.invalidate(rideParticipantsProvider(rideId));
    invalidateRideLists(_ref);
  }
}
