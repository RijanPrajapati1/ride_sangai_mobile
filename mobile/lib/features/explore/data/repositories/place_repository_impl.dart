import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/utils/geo.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/place_review.dart';
import '../../domain/repositories/place_repository.dart';
import '../datasources/place_local_datasource.dart';
import '../dto/place_dto.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  final PlaceLocalDataSource _dataSource;

  PlaceRepositoryImpl(this._dataSource);

  @override
  Future<List<Place>> getPlaces(PlaceQuery query) async {
    final dtos = await _dataSource.getPlaces(query);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Place> getPlaceById(String id, {GeoPoint? from}) async {
    final dto = await _dataSource.getPlaceById(id, from: from);
    return dto.toEntity();
  }

  @override
  Future<List<PlaceReview>> getReviews(String placeId) async {
    final dtos = await _dataSource.getReviews(placeId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<Place>> getSavedPlaces({GeoPoint? from}) async {
    final dtos = await _dataSource.getSavedPlaces(from: from);
    return dtos.map((d) => d.toEntity()).toList();
  }

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
    String? blankToNull(String? value) => (value == null || value.trim().isEmpty) ? null : value.trim();
    final dto = await _dataSource.sharePlace(
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
        bestTime: blankToNull(bestTime),
        tips: blankToNull(tips),
        entryFee: blankToNull(entryFee),
        authorId: '',
        authorName: '',
        authorAvatarUrl: '',
        createdAt: DateTime.now(),
      ),
    );
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
  }) async {
    final dto = await _dataSource.submitReview(
      placeId: placeId,
      rating: rating,
      worthIt: worthIt,
      text: text,
      visitedOn: visitedOn,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deleteReview(String placeId) => _dataSource.deleteReview(placeId);

  @override
  Future<void> deletePlace(String placeId) => _dataSource.deletePlace(placeId);
}
