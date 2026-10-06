import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/dashboard_category_provider.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/location/location_service.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/place_remote_datasource.dart';
import '../../data/repositories/place_repository_impl.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/place_review.dart';
import '../../domain/repositories/place_repository.dart';
import '../../domain/usecases/get_places.dart';
import '../../domain/usecases/submit_place_review.dart';
import '../../domain/usecases/toggle_save_place.dart';

final placeRemoteDataSourceProvider = Provider<PlaceRemoteDataSource>((ref) {
  return PlaceRemoteDataSource(ref.watch(sessionApiClientProvider));
});

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  return PlaceRepositoryImpl(ref.watch(placeRemoteDataSourceProvider));
});

/// Explore screen filter state; maps 1:1 onto the API's query params.
class ExploreFilters {
  final PlaceCategory? category;
  final String query;
  final PlaceSort sort;

  /// null = any distance.
  final double? radiusKm;

  /// Only places that suit the active dashboard (cycling, trekking, …).
  final bool matchDashboard;

  const ExploreFilters({
    this.category,
    this.query = '',
    this.sort = PlaceSort.nearest,
    this.radiusKm = 50,
    this.matchDashboard = false,
  });

  bool get isActive => category != null || query.isNotEmpty || matchDashboard;

  ExploreFilters copyWith({
    PlaceCategory? category,
    bool clearCategory = false,
    String? query,
    PlaceSort? sort,
    double? radiusKm,
    bool clearRadius = false,
    bool? matchDashboard,
  }) {
    return ExploreFilters(
      category: clearCategory ? null : (category ?? this.category),
      query: query ?? this.query,
      sort: sort ?? this.sort,
      radiusKm: clearRadius ? null : (radiusKm ?? this.radiusKm),
      matchDashboard: matchDashboard ?? this.matchDashboard,
    );
  }
}

final exploreFiltersProvider = StateProvider<ExploreFilters>((ref) => const ExploreFilters());

/// The Explore list for the current filters and the rider's location.
final explorePlacesProvider = FutureProvider<List<Place>>((ref) async {
  final filters = ref.watch(exploreFiltersProvider);
  final location = await ref.watch(currentLocationProvider.future);
  final DashboardCategory? activity = filters.matchDashboard ? ref.watch(selectedDashboardCategoryProvider) : null;
  return GetPlaces(ref.watch(placeRepositoryProvider))(
    PlaceQuery(
      from: location.point,
      radiusKm: filters.sort == PlaceSort.nearest ? filters.radiusKm : null,
      category: filters.category,
      activity: activity,
      query: filters.query,
      sort: filters.sort,
    ),
  );
});

/// Home "Explore nearby": the closest places that suit the active dashboard
/// (falls back to any nearby place when none match).
final homeExplorePlacesProvider = FutureProvider<List<Place>>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  final activity = ref.watch(selectedDashboardCategoryProvider);
  final repository = ref.watch(placeRepositoryProvider);
  final matching = await repository.getPlaces(
    PlaceQuery(from: location.point, radiusKm: 100, activity: activity, sort: PlaceSort.nearest),
  );
  if (matching.isNotEmpty) return matching.take(6).toList();
  final any = await repository.getPlaces(PlaceQuery(from: location.point, radiusKm: 100));
  return any.take(6).toList();
});

final placeDetailsProvider = FutureProvider.family<Place, String>((ref, id) async {
  final location = await ref.watch(currentLocationProvider.future);
  return ref.watch(placeRepositoryProvider).getPlaceById(id, from: location.point);
});

final placeReviewsProvider = FutureProvider.family<List<PlaceReview>, String>((ref, placeId) {
  return ref.watch(placeRepositoryProvider).getReviews(placeId);
});

final savedPlacesProvider = FutureProvider<List<Place>>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  return ref.watch(placeRepositoryProvider).getSavedPlaces(from: location.point);
});

/// Places a rider has shared (`GET /users/:id/places`), newest first.
final userPlacesProvider = FutureProvider.family<List<Place>, String>((ref, userId) async {
  final location = await ref.watch(currentLocationProvider.future);
  return ref.watch(placeRepositoryProvider).getPlacesByUser(userId, from: location.point);
});

final exploreActionsControllerProvider = Provider((ref) => ExploreActionsController(ref));

class ExploreActionsController {
  final Ref _ref;

  ExploreActionsController(this._ref);

  PlaceRepository get _repository => _ref.read(placeRepositoryProvider);

  void _refreshPlace(String placeId) {
    _ref.invalidate(placeDetailsProvider(placeId));
    _ref.invalidate(explorePlacesProvider);
    _ref.invalidate(homeExplorePlacesProvider);
    _ref.invalidate(savedPlacesProvider);
    _ref.invalidate(userPlacesProvider);
  }

  Future<void> toggleSave(String placeId, {required bool isCurrentlySaved}) async {
    await ToggleSavePlace(_repository)(placeId, isCurrentlySaved: isCurrentlySaved);
    _refreshPlace(placeId);
  }

  Future<void> submitReview({
    required String placeId,
    required int rating,
    required bool worthIt,
    required String text,
    DateTime? visitedOn,
    List<String> photos = const [],
  }) async {
    await SubmitPlaceReview(_repository)(
      placeId: placeId,
      rating: rating,
      worthIt: worthIt,
      text: text,
      visitedOn: visitedOn,
      photos: photos,
    );
    _ref.invalidate(placeReviewsProvider(placeId));
    _refreshPlace(placeId);
  }

  Future<void> deleteReview(String placeId) async {
    await _repository.deleteReview(placeId);
    _ref.invalidate(placeReviewsProvider(placeId));
    _refreshPlace(placeId);
  }

  Future<Place> sharePlace({
    required String name,
    required String description,
    required PlaceCategory category,
    required double latitude,
    required double longitude,
    required String locationName,
    required List<String> photos,
    required List<DashboardCategory> activities,
    String? bestTime,
    String? tips,
    String? entryFee,
  }) async {
    final place = await _repository.sharePlace(
      name: name,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      photos: photos,
      activities: activities,
      bestTime: bestTime,
      tips: tips,
      entryFee: entryFee,
    );
    _ref.invalidate(explorePlacesProvider);
    _ref.invalidate(homeExplorePlacesProvider);
    _ref.invalidate(userPlacesProvider);
    return place;
  }

  /// Author or superadmin; only the given fields change.
  Future<Place> updatePlace(
    String placeId, {
    String? name,
    String? description,
    PlaceCategory? category,
    double? latitude,
    double? longitude,
    String? locationName,
    List<String>? photos,
    List<DashboardCategory>? activities,
    String? bestTime,
    String? tips,
    String? entryFee,
  }) async {
    final place = await _repository.updatePlace(
      placeId,
      name: name,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      photos: photos,
      activities: activities,
      bestTime: bestTime,
      tips: tips,
      entryFee: entryFee,
    );
    _refreshPlace(placeId);
    return place;
  }

  Future<void> deletePlace(String placeId) async {
    await _repository.deletePlace(placeId);
    _refreshPlace(placeId);
  }
}
