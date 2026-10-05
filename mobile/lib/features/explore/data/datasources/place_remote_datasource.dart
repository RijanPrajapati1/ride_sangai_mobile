import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated.dart';
import '../dto/place_dto.dart';
import '../dto/place_review_dto.dart';

/// Server-side sort for `GET /places`.
enum PlaceListSort { top, newest }

/// A place's "want to go" state after saving or unsaving.
typedef PlaceSaveState = ({bool isSaved, int saveCount});

/// Calls the Explore endpoints (`/places`, `/me/saved-places`, `/users/:id/places`).
class PlaceRemoteDataSource {
  static const placesPath = '/places';
  static const nearbyPath = '/places/nearby';
  static const savedPlacesPath = '/me/saved-places';
  static String placePath(String id) => '/places/$id';
  static String savePath(String id) => '/places/$id/save';
  static String reviewsPath(String id) => '/places/$id/reviews';
  static String reviewPath(String id) => '/places/$id/review';
  static String userPlacesPath(String userId) => '/users/$userId/places';

  /// The API's maximum page size.
  static const maxLimit = 100;

  final ApiClient _api;

  PlaceRemoteDataSource(this._api);

  static Map<String, dynamic> _filters({
    PlaceCategory? category,
    DashboardCategory? activity,
    double? minRating,
    String? q,
  }) =>
      {
        'category': category?.name,
        'activity': activity?.name,
        'minRating': minRating,
        'q': (q == null || q.trim().isEmpty) ? null : q.trim(),
      };

  Future<Paginated<PlaceDto>> _getPage(String path, Map<String, dynamic> query) async {
    final json = await _api.get<Map<String, dynamic>>(path, query: query);
    return Paginated.fromJson(json, PlaceDto.fromJson);
  }

  /// Places within [radiusKm] (server default 25, max 300) of lat/lng, nearest first.
  Future<Paginated<PlaceDto>> getNearby({
    required double lat,
    required double lng,
    double? radiusKm,
    PlaceCategory? category,
    DashboardCategory? activity,
    double? minRating,
    String? q,
    String? cursor,
    int limit = 50,
  }) =>
      _getPage(nearbyPath, {
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        ..._filters(category: category, activity: activity, minRating: minRating, q: q),
        'cursor': cursor,
        'limit': limit,
      });

  /// Browse all places, best rated or newest. Pass lat/lng to get `distanceKm`.
  Future<Paginated<PlaceDto>> getPlaces({
    PlaceListSort sort = PlaceListSort.top,
    double? lat,
    double? lng,
    PlaceCategory? category,
    DashboardCategory? activity,
    double? minRating,
    String? q,
    String? cursor,
    int limit = 50,
  }) =>
      _getPage(placesPath, {
        'sort': sort.name,
        'lat': lat,
        'lng': lng,
        ..._filters(category: category, activity: activity, minRating: minRating, q: q),
        'cursor': cursor,
        'limit': limit,
      });

  Future<PlaceDto> getPlace(String id, {double? lat, double? lng}) async {
    final json = await _api.get<Map<String, dynamic>>(placePath(id), query: {'lat': lat, 'lng': lng});
    return PlaceDto.fromJson(json);
  }

  Future<PlaceDto> createPlace(PlaceDto draft) async {
    final json = await _api.post<Map<String, dynamic>>(placesPath, data: draft.toCreateJson());
    return PlaceDto.fromJson(json);
  }

  /// Partial update (author or admin). [fields] uses the `POST /places` keys.
  Future<PlaceDto> updatePlace(String id, Map<String, dynamic> fields) async {
    final json = await _api.patch<Map<String, dynamic>>(placePath(id), data: fields);
    return PlaceDto.fromJson(json);
  }

  Future<void> deletePlace(String id) => _api.delete<dynamic>(placePath(id));

  Future<PlaceSaveState> savePlace(String id) async =>
      _saveState(await _api.put<Map<String, dynamic>>(savePath(id)));

  Future<PlaceSaveState> unsavePlace(String id) async =>
      _saveState(await _api.delete<Map<String, dynamic>>(savePath(id)));

  static PlaceSaveState _saveState(Map<String, dynamic> json) =>
      (isSaved: json['isSaved'] as bool, saveCount: json['saveCount'] as int);

  /// Newest first.
  Future<Paginated<PlaceReviewDto>> getReviews(String placeId, {String? cursor, int limit = 50}) async {
    final json = await _api.get<Map<String, dynamic>>(
      reviewsPath(placeId),
      query: {'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, PlaceReviewDto.fromJson);
  }

  /// Creates or replaces my review (one per rider per place).
  Future<PlaceReviewDto> putReview(
    String placeId, {
    required int rating,
    required bool worthIt,
    String text = '',
    String? visitedOn,
    List<String> photos = const [],
  }) async {
    final json = await _api.put<Map<String, dynamic>>(
      reviewPath(placeId),
      data: {'rating': rating, 'worthIt': worthIt, 'text': text, 'visitedOn': visitedOn, 'photos': photos},
    );
    return PlaceReviewDto.fromJson(json);
  }

  Future<void> deleteReview(String placeId) => _api.delete<dynamic>(reviewPath(placeId));

  /// My "want to go" list, most recently saved first.
  Future<Paginated<PlaceDto>> getSavedPlaces({double? lat, double? lng, String? cursor, int limit = 50}) =>
      _getPage(savedPlacesPath, {'lat': lat, 'lng': lng, 'cursor': cursor, 'limit': limit});

  /// Places a rider has shared, newest first.
  Future<Paginated<PlaceDto>> getUserPlaces(
    String userId, {
    double? lat,
    double? lng,
    String? cursor,
    int limit = 50,
  }) =>
      _getPage(userPlacesPath(userId), {'lat': lat, 'lng': lng, 'cursor': cursor, 'limit': limit});
}
