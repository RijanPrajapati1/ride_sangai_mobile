import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../data/datasources/ride_local_datasource.dart';
import '../../data/repositories/ride_repository_impl.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_participant.dart';
import '../../domain/repositories/ride_repository.dart';
import '../../domain/usecases/cancel_ride_request.dart';
import '../../domain/usecases/request_to_join_ride.dart';

final rideLocalDataSourceProvider = Provider<RideLocalDataSource>((ref) {
  return RideLocalDataSource();
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepositoryImpl(ref.watch(rideLocalDataSourceProvider));
});

final upcomingRidesProvider = FutureProvider<List<Ride>>((ref) {
  return ref.watch(rideRepositoryProvider).getUpcomingRides();
});

final rideDetailsProvider = FutureProvider.family<Ride, String>((ref, rideId) {
  return ref.watch(rideRepositoryProvider).getRideById(rideId);
});

final rideParticipantsProvider = FutureProvider.family<List<RideParticipant>, String>((ref, rideId) {
  return ref.watch(rideRepositoryProvider).getParticipants(rideId);
});

final organizedRidesProvider = FutureProvider<List<Ride>>((ref) {
  return ref.watch(rideRepositoryProvider).getOrganizedRides(AppConstants.currentUserId);
});

final joinedRidesProvider = FutureProvider<List<Ride>>((ref) {
  return ref.watch(rideRepositoryProvider).getJoinedRides(AppConstants.currentUserId);
});

final pastRidesProvider = FutureProvider<List<Ride>>((ref) {
  return ref.watch(rideRepositoryProvider).getPastRides(AppConstants.currentUserId);
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

  bool get isActive => query.isNotEmpty || type != null || difficulty != null;
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

final filteredRidesProvider = Provider<AsyncValue<List<Ride>>>((ref) {
  final ridesAsync = ref.watch(upcomingRidesProvider);
  final filters = ref.watch(rideFiltersProvider);
  return ridesAsync.whenData((rides) {
    return rides.where((ride) {
      final matchesQuery = filters.query.isEmpty ||
          ride.title.toLowerCase().contains(filters.query.toLowerCase()) ||
          ride.meetingPoint.toLowerCase().contains(filters.query.toLowerCase());
      final matchesType = filters.type == null || ride.rideType == filters.type;
      final matchesDifficulty = filters.difficulty == null || ride.difficulty == filters.difficulty;
      return matchesQuery && matchesType && matchesDifficulty;
    }).toList();
  });
});

final rideActionsControllerProvider = Provider((ref) => RideActionsController(ref));

class RideActionsController {
  final Ref _ref;

  RideActionsController(this._ref);

  Future<void> requestToJoin(String rideId) async {
    await RequestToJoinRide(_ref.read(rideRepositoryProvider))(rideId);
    _invalidateAll(rideId);
  }

  Future<void> cancelRequest(String rideId) async {
    await CancelRideRequest(_ref.read(rideRepositoryProvider))(rideId);
    _invalidateAll(rideId);
  }

  void _invalidateAll(String rideId) {
    _ref.invalidate(rideDetailsProvider(rideId));
    _ref.invalidate(upcomingRidesProvider);
    _ref.invalidate(joinedRidesProvider);
    _ref.invalidate(organizedRidesProvider);
  }
}
