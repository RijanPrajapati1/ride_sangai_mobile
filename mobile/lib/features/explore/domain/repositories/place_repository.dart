import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/utils/geo.dart';
import '../entities/place.dart';
import '../entities/place_review.dart';

enum PlaceSort { nearest, topRated, newest }

class PlaceQuery {
  final GeoPoint? from;
  final double? radiusKm;
  final PlaceCategory? category;
  final DashboardCategory? activity;
  final String query;
  final PlaceSort sort;

  const PlaceQuery({
    this.from,
    this.radiusKm,
    this.category,
    this.activity,
    this.query = '',
    this.sort = PlaceSort.nearest,
  });
}

abstract class PlaceRepository {
  /// Explore list: filtered and sorted; `distanceKm` is set when [PlaceQuery.from] is given.
  Future<List<Place>> getPlaces(PlaceQuery query);
  Future<Place> getPlaceById(String id, {GeoPoint? from});
  Future<List<PlaceReview>> getReviews(String placeId);
  Future<List<Place>> getSavedPlaces({GeoPoint? from});

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
  });

  Future<void> savePlace(String placeId);
  Future<void> unsavePlace(String placeId);

  /// Creates or replaces the current rider's review.
  Future<PlaceReview> submitReview({
    required String placeId,
    required int rating,
    required bool worthIt,
    required String text,
    DateTime? visitedOn,
  });
  Future<void> deleteReview(String placeId);

  /// Author or admin.
  Future<void> deletePlace(String placeId);
}
