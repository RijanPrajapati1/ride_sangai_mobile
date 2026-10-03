import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sangai/core/enums/dashboard_category.dart';
import 'package:ride_sangai/core/enums/place_category.dart';
import 'package:ride_sangai/core/errors/app_exception.dart';
import 'package:ride_sangai/core/utils/geo.dart';
import 'package:ride_sangai/features/explore/data/datasources/place_local_datasource.dart';
import 'package:ride_sangai/features/explore/data/dto/place_dto.dart';
import 'package:ride_sangai/features/explore/domain/repositories/place_repository.dart';

// Thamel, Kathmandu
const thamel = GeoPoint(27.7154, 85.3123);

void main() {
  group('geo', () {
    test('haversine distance Thamel → Taudaha is about 9 km', () {
      final km = distanceKm(thamel, const GeoPoint(27.6476, 85.2813));
      expect(km, closeTo(8.2, 1));
    });

    test('formats distances for display', () {
      expect(formatDistance(0.42), '420 m');
      expect(formatDistance(4.26), '4.3 km');
      expect(formatDistance(38.4), '38 km');
    });
  });

  group('PlaceLocalDataSource', () {
    late PlaceLocalDataSource source;

    setUp(() => source = PlaceLocalDataSource());

    test('nearby places are sorted by distance and limited by radius', () async {
      final places = await source.getPlaces(const PlaceQuery(from: thamel, radiusKm: 15));
      expect(places, isNotEmpty);
      final distances = places.map((p) => p.distanceKm!).toList();
      expect(distances, orderedEquals([...distances]..sort()));
      expect(distances.every((d) => d <= 15), isTrue);
      expect(places.any((p) => p.name == 'Namobuddha Monastery'), isFalse, reason: 'about 32 km away');
    });

    test('filters by category, activity and text', () async {
      final lakes = await source.getPlaces(const PlaceQuery(category: PlaceCategory.lake));
      expect(lakes.map((p) => p.name), ['Taudaha Lake']);
      final riding = await source.getPlaces(const PlaceQuery(activity: DashboardCategory.riding));
      expect(riding.every((p) => p.activities.contains(DashboardCategory.riding)), isTrue);
      final search = await source.getPlaces(const PlaceQuery(query: 'kavre'));
      expect(search.map((p) => p.name).toSet(), {'Namobuddha Monastery', 'Panauti Old Town'});
    });

    test('seeded aggregates match the reviews', () async {
      final sundarijal = await source.getPlaceById('pl_003');
      expect(sundarijal.averageRating, 3.0);
      expect(sundarijal.reviewCount, 2);
      expect(sundarijal.worthItPercent, 50);
      final taudaha = await source.getPlaceById('pl_001');
      expect(taudaha.myReview?.rating, 5, reason: 'the demo rider reviewed it');
    });

    test('reviewing updates aggregates; editing replaces the review', () async {
      await source.submitReview(placeId: 'pl_006', rating: 3, worthIt: false, text: 'Too crowded');
      var panauti = await source.getPlaceById('pl_006');
      expect(panauti.reviewCount, 2);
      expect(panauti.averageRating, 4.0);
      expect(panauti.worthItPercent, 50);

      await source.submitReview(placeId: 'pl_006', rating: 5, worthIt: true, text: 'Changed my mind!');
      panauti = await source.getPlaceById('pl_006');
      expect(panauti.reviewCount, 2);
      expect(panauti.averageRating, 5.0);
      expect(panauti.worthItPercent, 100);

      await source.deleteReview('pl_006');
      panauti = await source.getPlaceById('pl_006');
      expect(panauti.reviewCount, 1);
      expect(panauti.myReview, isNull);
    });

    test('cannot review a place you shared', () async {
      final mine = await source.sharePlace(
        PlaceDto(
          id: '',
          name: 'Secret Spot',
          description: 'Shh',
          category: PlaceCategory.cave,
          latitude: 27.7,
          longitude: 85.3,
          locationName: 'Somewhere',
          photos: const [],
          activities: const [],
          authorId: '',
          authorName: '',
          authorAvatarUrl: '',
          createdAt: DateTime.now(),
        ),
      );
      expect(mine.isMine, isTrue);
      expect(
        () => source.submitReview(placeId: mine.id, rating: 5, worthIt: true, text: ''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('saving is idempotent and updates the count', () async {
      final before = (await source.getPlaceById('pl_006')).saveCount;
      await source.savePlace('pl_006');
      await source.savePlace('pl_006');
      final saved = await source.getPlaceById('pl_006');
      expect(saved.isSaved, isTrue);
      expect(saved.saveCount, before + 1);
      expect((await source.getSavedPlaces()).map((p) => p.id), contains('pl_006'));
      await source.unsavePlace('pl_006');
      expect((await source.getPlaceById('pl_006')).saveCount, before);
    });
  });

  test('PlaceDto parses the API response shape', () {
    final dto = PlaceDto.fromJson({
      'id': '0193',
      'name': 'Kakani Viewpoint',
      'description': 'Views',
      'category': 'viewpoint',
      'latitude': 27.804,
      'longitude': 85.2546,
      'locationName': 'Kakani, Nuwakot',
      'photos': ['https://example.com/a.jpg'],
      'coverImageUrl': 'https://example.com/a.jpg',
      'activities': ['riding', 'cycling'],
      'bestTime': null,
      'tips': null,
      'entryFee': 'Free',
      'averageRating': 4.5,
      'reviewCount': 2,
      'worthItPercent': 100,
      'saveCount': 1,
      'distanceKm': 12.3,
      'authorId': 'u1',
      'authorName': 'Nischal Karki',
      'authorAvatarUrl': '',
      'isMine': false,
      'isSaved': true,
      'myReview': {'id': 'r1', 'rating': 4, 'worthIt': true},
      'createdAt': '2026-10-01T10:00:00.000Z',
    });
    final place = dto.toEntity();
    expect(place.category, PlaceCategory.viewpoint);
    expect(place.activities, [DashboardCategory.riding, DashboardCategory.cycling]);
    expect(place.coverImageUrl, 'https://example.com/a.jpg');
    expect(place.myReview?.rating, 4);
    expect(place.distanceKm, 12.3);
  });
}
