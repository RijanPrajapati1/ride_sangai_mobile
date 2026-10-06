import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../community/domain/entities/community_post.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../ride_requests/domain/entities/ride_request.dart';
import '../../../ride_requests/presentation/providers/ride_request_providers.dart';
import '../../../rides/domain/entities/ride.dart';
import '../../../rides/presentation/providers/ride_providers.dart';

final superadminAllUsersProvider = FutureProvider<List<UserProfile>>((ref) {
  return ref.watch(userRepositoryProvider).getAllUsers();
});

final superadminAllRidesProvider = FutureProvider<List<Ride>>((ref) {
  return ref.watch(rideRepositoryProvider).getAllRides();
});

final superadminAllRequestsProvider = FutureProvider<List<RideRequest>>((ref) {
  return ref.watch(rideRequestRepositoryProvider).getAllRequests();
});

final superadminAllPostsProvider = FutureProvider<List<CommunityPost>>((ref) {
  return ref.watch(communityRepositoryProvider).getAllPostsForSuperadmin();
});

final superadminActionsControllerProvider = Provider((ref) => SuperadminActionsController(ref));

class SuperadminActionsController {
  final Ref _ref;

  SuperadminActionsController(this._ref);

  Future<void> removeUser(String userId) async {
    await _ref.read(userRepositoryProvider).removeUser(userId);
    _ref.invalidate(superadminAllUsersProvider);
    _ref.invalidate(recommendedRidersProvider);
  }

  Future<void> deleteRide(String rideId) async {
    await _ref.read(rideRepositoryProvider).deleteRide(rideId);
    _ref.invalidate(superadminAllRidesProvider);
    _ref.invalidate(upcomingRidesProvider);
  }

  Future<void> deletePost(String postId) async {
    await _ref.read(communityRepositoryProvider).superadminDeletePost(postId);
    _ref.invalidate(superadminAllPostsProvider);
    _ref.invalidate(communityPostsProvider);
  }

  Future<void> approveRequest(String requestId) async {
    await _ref.read(rideRequestRepositoryProvider).approve(requestId);
    _ref.invalidate(superadminAllRequestsProvider);
    _ref.invalidate(organizerRequestsProvider);
  }

  Future<void> declineRequest(String requestId) async {
    await _ref.read(rideRequestRepositoryProvider).decline(requestId);
    _ref.invalidate(superadminAllRequestsProvider);
    _ref.invalidate(organizerRequestsProvider);
  }
}
