import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/dashboard_category_provider.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../data/datasources/ride_remote_datasource.dart';
import '../../data/repositories/ride_repository_impl.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_participant.dart';
import '../../domain/repositories/ride_repository.dart';
import '../../domain/usecases/cancel_ride_request.dart';
import '../../domain/usecases/get_upcoming_rides.dart';
import '../../domain/usecases/request_to_join_ride.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';

final rideRemoteDataSourceProvider = Provider<RideRemoteDataSource>((ref) {
  return RideRemoteDataSource(ref.watch(sessionApiClientProvider));
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepositoryImpl(
    ref.watch(rideRemoteDataSourceProvider),
    () => ref.read(currentUserIdProvider),
  );
});

/// Upcoming rides in the active dashboard category (Cycling/Trekking/Hiking/
/// Riding), soonest first. Filtered by the server.
final upcomingRidesProvider = FutureProvider<List<Ride>>((ref) {
  final category = ref.watch(selectedDashboardCategoryProvider);
  return GetUpcomingRides(ref.watch(rideRepositoryProvider))(category: category);
});

/// Upcoming rides scoped to the active dashboard, for the Home screen and any
/// other category-aware surface.
final dashboardUpcomingRidesProvider = Provider<AsyncValue<List<Ride>>>((ref) {
  return ref.watch(upcomingRidesProvider);
});

final rideDetailsProvider = FutureProvider.family<Ride, String>((ref, rideId) {
  return ref.watch(rideRepositoryProvider).getRideById(rideId);
});

final rideParticipantsProvider = FutureProvider.family<List<RideParticipant>, String>((ref, rideId) {
  return ref.watch(rideRepositoryProvider).getParticipants(rideId);
});

/// Future rides the signed-in rider organizes, joined or requested.
final myUpcomingRidesProvider = FutureProvider<List<Ride>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(rideRepositoryProvider).getMyUpcomingRides();
});

final organizedRidesProvider = FutureProvider<List<Ride>>((ref) {
  return ref.watch(rideRepositoryProvider).getOrganizedRides(ref.watch(currentUserIdProvider));
});

final userOrganizedRidesProvider = FutureProvider.family<List<Ride>, String>((ref, userId) {
  return ref.watch(rideRepositoryProvider).getOrganizedRides(userId);
});

final joinedRidesProvider = FutureProvider<List<Ride>>((ref) {
  return ref.watch(rideRepositoryProvider).getJoinedRides(ref.watch(currentUserIdProvider));
});

final pastRidesProvider = FutureProvider<List<Ride>>((ref) {
  return ref.watch(rideRepositoryProvider).getPastRides(ref.watch(currentUserIdProvider));
});

/// Search + filter state for the ride discovery screen.
class RideFilters {
  final String query;
  final RideType? type;
  final RideDifficulty? difficulty;

  const RideFilters({this.query = '', this.type, this.difficulty});

  RideFilters copyWith({String? query, RideType? type, bool clearType = false, RideDifficulty? difficulty, bool clearDifficulty = false}) {
    return RideFilters(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
    );
  }

  bool get isActive => query.trim().isNotEmpty || type != null || difficulty != null;
}

class RideFiltersController extends StateNotifier<RideFilters> {
  RideFiltersController() : super(const RideFilters());

  void setQuery(String query) => state = state.copyWith(query: query);
  void setType(RideType? type) => state = state.copyWith(type: type, clearType: type == null);
  void setDifficulty(RideDifficulty? difficulty) =>
      state = state.copyWith(difficulty: difficulty, clearDifficulty: difficulty == null);
  void clear() => state = const RideFilters();
}

final rideFiltersProvider = StateNotifierProvider<RideFiltersController, RideFilters>((ref) {
  return RideFiltersController();
});

/// Upcoming rides matching the discovery screen's search and filters. With no
/// filters this is just [upcomingRidesProvider]; otherwise the server filters
/// (search typing is debounced so each keystroke doesn't hit the API).
final filteredRidesProvider = FutureProvider<List<Ride>>((ref) async {
  final filters = ref.watch(rideFiltersProvider);
  if (!filters.isActive) return ref.watch(upcomingRidesProvider.future);

  final category = ref.watch(selectedDashboardCategoryProvider);
  final repository = ref.watch(rideRepositoryProvider);
  // Refetch whenever the unfiltered list is refreshed (pull to refresh, after
  // joining, creating or deleting a ride).
  ref.watch(upcomingRidesProvider);

  if (filters.query.trim().isNotEmpty) {
    var disposed = false;
    ref.onDispose(() => disposed = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (disposed) return const [];
  }

  // A type from another category can't match; skip it rather than send it.
  final type = filters.type?.category == category ? filters.type : null;
  return GetUpcomingRides(repository)(
    category: category,
    rideType: type,
    difficulty: filters.difficulty,
    query: filters.query,
  );
});

final rideActionsControllerProvider = Provider((ref) => RideActionsController(ref));

class RideActionsController {
  final Ref _ref;

  RideActionsController(this._ref);

  Future<void> requestToJoin(String rideId, {String? message}) async {
    await RequestToJoinRide(_ref.read(rideRepositoryProvider))(rideId, message: message);
    _invalidateAll(rideId);
  }

  Future<void> cancelRequest(String rideId) async {
    await CancelRideRequest(_ref.read(rideRepositoryProvider))(rideId);
    _invalidateAll(rideId);
  }

  /// Organizer: cancels (deletes) the ride.
  Future<void> cancelRide(String rideId) async {
    await _ref.read(rideRepositoryProvider).cancelRide(rideId);
    _invalidateAll(rideId);
  }

  void _invalidateAll(String rideId) {
    _ref.invalidate(rideDetailsProvider(rideId));
    _ref.invalidate(rideParticipantsProvider(rideId));
    invalidateRideLists(_ref);
  }
}

/// Refreshes every ride list after something changed.
void invalidateRideLists(Ref ref) {
  ref.invalidate(upcomingRidesProvider);
  ref.invalidate(myUpcomingRidesProvider);
  ref.invalidate(joinedRidesProvider);
  ref.invalidate(organizedRidesProvider);
  ref.invalidate(pastRidesProvider);
  ref.invalidate(userOrganizedRidesProvider);
}
