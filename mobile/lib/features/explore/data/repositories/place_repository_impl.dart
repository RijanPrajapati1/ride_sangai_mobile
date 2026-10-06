import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/utils/geo.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/place_review.dart';
import '../../domain/repositories/place_repository.dart';
import '../datasources/place_remote_datasource.dart';
import '../dto/place_dto.dart';
import '../dto/place_review_dto.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  /// "Any distance" still needs a radius for `/places/nearby`; this is the API's maximum.
  static const maxRadiusKm = 300.0;

  final PlaceRemoteDataSource _dataSource;

  PlaceRepositoryImpl(this._dataSource);

  @override
  Future<List<Place>> getPlaces(PlaceQuery query) async {
    final from = query.from;
    final q = query.query.trim().isEmpty ? null : query.query.trim();
    final page = (query.sort == PlaceSort.nearest && from != null)
        ? await _dataSource.getNearby(
            lat: from.latitude,
            lng: from.longitude,
            radiusKm: (query.radiusKm ?? maxRadiusKm).clamp(0.1, maxRadiusKm).toDouble(),
            category: query.category,
            activity: query.activity,
            minRating: query.minRating,
            q: q,
            limit: PlaceRemoteDataSource.maxLimit,
          )
        : await _dataSource.getPlaces(
            sort: query.sort == PlaceSort.newest ? PlaceListSort.newest : PlaceListSort.top,
            lat: from?.latitude,
            lng: from?.longitude,
            category: query.category,
            activity: query.activity,
            minRating: query.minRating,
            q: q,
            limit: PlaceRemoteDataSource.maxLimit,
          );
    return page.items.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Place> getPlaceById(String id, {GeoPoint? from}) async {
    final dto = await _dataSource.getPlace(id, lat: from?.latitude, lng: from?.longitude);
    return dto.toEntity();
  }

  @override
  Future<List<PlaceReview>> getReviews(String placeId) async {
    final page = await _dataSource.getReviews(placeId);
    return page.items.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<Place>> getSavedPlaces({GeoPoint? from}) async {
    final page = await _dataSource.getSavedPlaces(
      lat: from?.latitude,
      lng: from?.longitude,
      limit: PlaceRemoteDataSource.maxLimit,
    );
    return page.items.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<Place>> getPlacesByUser(String userId, {GeoPoint? from}) async {
    final page = await _dataSource.getUserPlaces(
      userId,
      lat: from?.latitude,
      lng: from?.longitude,
      limit: PlaceRemoteDataSource.maxLimit,
    );
    return page.items.map((d) => d.toEntity()).toList();
  }

  static String? _blankToNull(String? value) => (value == null || value.trim().isEmpty) ? null : value.trim();

  @override
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
    final dto = await _dataSource.createPlace(
      PlaceDto(
        id: '',
        name: name.trim(),
        description: description.trim(),
        category: category,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName.trim(),
        photos: photos,
        activities: activities,
        bestTime: _blankToNull(bestTime),
        tips: _blankToNull(tips),
        entryFee: _blankToNull(entryFee),
        authorId: '',
        authorName: '',
        authorAvatarUrl: '',
        createdAt: DateTime.now(),
      ),
    );
    return dto.toEntity();
  }

  @override
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
    final fields = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (description != null) 'description': description.trim(),
      if (category != null) 'category': category.name,
      'latitude': ?latitude,
      'longitude': ?longitude,
      if (locationName != null) 'locationName': locationName.trim(),
      'photos': ?photos,
      if (activities != null) 'activities': [for (final a in activities) a.name],
      if (bestTime != null) 'bestTime': _blankToNull(bestTime),
      if (tips != null) 'tips': _blankToNull(tips),
      if (entryFee != null) 'entryFee': _blankToNull(entryFee),
    };
    final dto = fields.isEmpty
        ? await _dataSource.getPlace(placeId)
        : await _dataSource.updatePlace(placeId, fields);
    return dto.toEntity();
  }

  @override
  Future<void> savePlace(String placeId) => _dataSource.savePlace(placeId);

  @override
  Future<void> unsavePlace(String placeId) => _dataSource.unsavePlace(placeId);

  @override
  Future<PlaceReview> submitReview({
    required String placeId,
    required int rating,
    required bool worthIt,
    required String text,
    DateTime? visitedOn,
    List<String> photos = const [],
  }) async {
    final dto = await _dataSource.putReview(
      placeId,
      rating: rating,
      worthIt: worthIt,
      text: text,
      visitedOn: visitedOn == null ? null : PlaceReviewDto.formatApiDay(visitedOn),
      photos: photos,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deleteReview(String placeId) => _dataSource.deleteReview(placeId);

  @override
  Future<void> deletePlace(String placeId) => _dataSource.deletePlace(placeId);
}
