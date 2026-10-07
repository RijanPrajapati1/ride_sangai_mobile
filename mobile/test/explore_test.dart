import 'package:flutter_test/flutter_test.dart';
import 'package:yatrix/core/enums/dashboard_category.dart';
import 'package:yatrix/core/enums/place_category.dart';
import 'package:yatrix/core/errors/app_exception.dart';
import 'package:yatrix/core/utils/geo.dart';
import 'package:yatrix/features/explore/data/datasources/place_remote_datasource.dart';
import 'package:yatrix/features/explore/data/dto/place_dto.dart';
import 'package:yatrix/features/explore/data/dto/place_review_dto.dart';
import 'package:yatrix/features/explore/data/repositories/place_repository_impl.dart';
import 'package:yatrix/features/explore/domain/repositories/place_repository.dart';
import 'package:yatrix/features/explore/domain/usecases/submit_place_review.dart';
import 'package:yatrix/features/explore/domain/usecases/toggle_save_place.dart';

import 'explore_fakes.dart';

// Thamel, Kathmandu
const thamel = GeoPoint(27.7154, 85.3123);

void main() {
  group('geo', () {
    test('haversine distance Thamel → Taudaha is about 8 km', () {
      final km = distanceKm(thamel, const GeoPoint(27.6476, 85.2813));
      expect(km, closeTo(8.2, 1));
    });

    test('formats distances for display', () {
      expect(formatDistance(0.42), '420 m');
      expect(formatDistance(4.26), '4.3 km');
      expect(formatDistance(38.4), '38 km');
    });
  });

  group('PlaceDto', () {
    test('parses the API response shape', () {
      final dto = PlaceDto.fromJson(placeJson(
        isSaved: true,
        myReview: {'id': 'r1', 'rating': 4, 'worthIt': true},
      ));
      final place = dto.toEntity();
      expect(place.category, PlaceCategory.viewpoint);
      expect(place.activities, [DashboardCategory.riding, DashboardCategory.cycling]);
      expect(place.coverImageUrl, 'https://example.com/a.jpg');
      expect(place.myReview?.rating, 4);
      expect(place.distanceKm, 12.3);
      expect(place.isSaved, isTrue);
      expect(place.tips, isNull);
      expect(place.createdAt.toUtc(), DateTime.utc(2026, 10, 1, 10));
    });

    test('toJson round-trips every API field', () {
      final json = placeJson(myReview: {'id': 'r1', 'rating': 4, 'worthIt': true});
      final back = PlaceDto.fromJson(json).toJson();
      expect(back.keys.toSet(), json.keys.toSet());
      for (final key in json.keys.where((k) => k != 'createdAt')) {
        expect(back[key], json[key], reason: key);
      }
      expect(DateTime.parse(back['createdAt'] as String), DateTime.parse(json['createdAt'] as String));
    });

    test('tolerates nulls, integer coordinates and unknown enum values', () {
      final dto = PlaceDto.fromJson({
        ...placeJson(),
        'category': 'skatepark',
        'activities': ['riding', 'paragliding'],
        'latitude': 27,
        'averageRating': null,
        'worthItPercent': null,
        'distanceKm': null,
      });
      expect(dto.category, PlaceCategory.other);
      expect(dto.activities, [DashboardCategory.riding]);
      expect(dto.latitude, 27.0);
      expect(dto.averageRating, isNull);
      expect(dto.distanceKm, isNull);
    });

    test('review DTO parses the API shape and builds the PUT body', () {
      final dto = PlaceReviewDto.fromJson(reviewJson());
      expect(dto.visitedOn, DateTime(2026, 9, 28));
      expect(dto.photos, ['https://example.com/r.jpg']);
      expect(dto.updatedAt?.toUtc(), DateTime.utc(2026, 10, 2, 9));
      expect(dto.toRequestJson(), {
        'rating': 4,
        'worthIt': true,
        'text': 'Lovely in the morning.',
        'visitedOn': '2026-09-28',
        'photos': ['https://example.com/r.jpg'],
      });
      expect(dto.toJson()['visitedOn'], '2026-09-28');
    });
  });

  group('PlaceRemoteDataSource + PlaceRepositoryImpl', () {
    late FakeAdapter adapter;
    late PlaceRemoteDataSource source;
    late PlaceRepository repository;

    Future<void> serve(({int status, Object? body}) Function(dynamic options) handler) async {
      adapter = FakeAdapter((options) => handler(options));
      source = PlaceRemoteDataSource(await fakeApiClient(adapter));
      repository = PlaceRepositoryImpl(source);
    }

    test('nearest uses /places/nearby with location, radius and filters', () async {
      await serve((_) => (status: 200, body: page([placeJson(id: 'a'), placeJson(id: 'b')])));
      final places = await repository.getPlaces(const PlaceQuery(
        from: thamel,
        radiusKm: 15,
        category: PlaceCategory.lake,
        activity: DashboardCategory.hiking,
        minRating: 4,
        query: '  kavre ',
      ));
      expect(places.map((p) => p.id), ['a', 'b']);
      final request = adapter.last;
      expect(request.method, 'GET');
      expect(request.path, '/places/nearby');
      expect(request.queryParameters, {
        'lat': 27.7154,
        'lng': 85.3123,
        'radiusKm': 15.0,
        'category': 'lake',
        'activity': 'hiking',
        'minRating': 4.0,
        'q': 'kavre',
        'limit': 100,
      });
      expect(request.headers['Authorization'], 'Bearer access');
    });

    test('"any distance" asks for the API maximum radius and omits empty filters', () async {
      await serve((_) => (status: 200, body: page([])));
      await repository.getPlaces(const PlaceQuery(from: thamel));
      expect(adapter.last.queryParameters['radiusKm'], 300.0);
      expect(adapter.last.queryParameters.keys, isNot(contains('q')));
      expect(adapter.last.queryParameters.keys, isNot(contains('category')));
    });

    test('top rated and newest use /places with the sort param', () async {
      await serve((_) => (status: 200, body: page([placeJson()])));
      await repository.getPlaces(const PlaceQuery(from: thamel, sort: PlaceSort.topRated));
      expect(adapter.last.path, '/places');
      expect(adapter.last.queryParameters, containsPair('sort', 'top'));
      expect(adapter.last.queryParameters, containsPair('lat', 27.7154));

      await repository.getPlaces(const PlaceQuery(sort: PlaceSort.newest));
      expect(adapter.last.queryParameters, {'sort': 'newest', 'limit': 100});

      // Without a location, "nearest" falls back to browsing.
      await repository.getPlaces(const PlaceQuery());
      expect(adapter.last.path, '/places');
    });

    test('pagination cursor is passed through and nextCursor parsed', () async {
      await serve((_) => (status: 200, body: page([placeJson()], 'next-1')));
      final result = await source.getPlaces(cursor: 'c0', limit: 10);
      expect(result.nextCursor, 'next-1');
      expect(result.hasMore, isTrue);
      expect(adapter.last.queryParameters, containsPair('cursor', 'c0'));
      expect(adapter.last.queryParameters, containsPair('limit', 10));
    });

    test('details, saved places and a rider\'s places', () async {
      await serve((options) => switch (options.path as String) {
            '/places/p1' => (status: 200, body: placeJson()),
            '/me/saved-places' => (status: 200, body: page([placeJson(isSaved: true)])),
            '/users/u2/places' => (status: 200, body: page([placeJson(), placeJson(id: 'p2')])),
            _ => (status: 404, body: apiError('NOT_FOUND', 'Nope.')),
          });
      final place = await repository.getPlaceById('p1', from: thamel);
      expect(place.name, 'Kakani Viewpoint');
      expect(adapter.last.queryParameters, {'lat': 27.7154, 'lng': 85.3123});

      final saved = await repository.getSavedPlaces(from: thamel);
      expect(saved.single.isSaved, isTrue);

      final byUser = await repository.getPlacesByUser('u2');
      expect(byUser, hasLength(2));
      expect(adapter.last.queryParameters, {'limit': 100});
    });

    test('sharing posts a trimmed body with blanks as null', () async {
      await serve((_) => (status: 201, body: placeJson(id: 'new', isMine: true)));
      final place = await repository.sharePlace(
        name: '  Secret Spot ',
        description: 'Shh',
        category: PlaceCategory.cave,
        latitude: 27.7,
        longitude: 85.3,
        locationName: 'Somewhere',
        photos: const ['https://cdn/x.jpg'],
        activities: const [DashboardCategory.hiking],
        bestTime: '   ',
        tips: ' Bring a torch ',
      );
      expect(place.isMine, isTrue);
      expect(adapter.last.method, 'POST');
      expect(adapter.last.path, '/places');
      expect(adapter.last.data, {
        'name': 'Secret Spot',
        'description': 'Shh',
        'category': 'cave',
        'latitude': 27.7,
        'longitude': 85.3,
        'locationName': 'Somewhere',
        'photos': ['https://cdn/x.jpg'],
        'activities': ['hiking'],
        'bestTime': null,
        'tips': 'Bring a torch',
        'entryFee': null,
      });
    });

    test('editing sends only the changed fields with PATCH', () async {
      await serve((_) => (status: 200, body: placeJson(name: 'Renamed')));
      final place = await repository.updatePlace('p1', name: ' Renamed ', entryFee: '');
      expect(place.name, 'Renamed');
      expect(adapter.last.method, 'PATCH');
      expect(adapter.last.path, '/places/p1');
      expect(adapter.last.data, {'name': 'Renamed', 'entryFee': null});
    });

    test('deleting a place', () async {
      await serve((_) => (status: 204, body: null));
      await repository.deletePlace('p1');
      expect(adapter.last.method, 'DELETE');
      expect(adapter.last.path, '/places/p1');
    });

    test('save uses PUT, unsave uses DELETE on /save', () async {
      var saved = false;
      await serve((options) {
        saved = options.method == 'PUT';
        return (status: 200, body: {'isSaved': saved, 'saveCount': saved ? 4 : 3});
      });
      expect(await source.savePlace('p1'), (isSaved: true, saveCount: 4));
      expect(adapter.last.path, '/places/p1/save');

      await ToggleSavePlace(repository)('p1', isCurrentlySaved: true);
      expect(adapter.last.method, 'DELETE');
      expect(saved, isFalse);
    });

    test('reviews: list, write (PUT) and delete', () async {
      await serve((options) => switch ((options.method as String, options.path as String)) {
            ('GET', '/places/p1/reviews') => (status: 200, body: page([reviewJson(), reviewJson(id: 'r2')])),
            ('PUT', '/places/p1/review') => (status: 201, body: {...reviewJson(id: 'mine'), 'isMine': true}),
            ('DELETE', '/places/p1/review') => (status: 204, body: null),
            _ => (status: 404, body: apiError('NOT_FOUND', 'Nope.')),
          });
      final reviews = await repository.getReviews('p1');
      expect(reviews.map((r) => r.id), ['r1', 'r2']);

      final review = await SubmitPlaceReview(repository)(
        placeId: 'p1',
        rating: 5,
        worthIt: true,
        text: '  Great  ',
        visitedOn: DateTime(2026, 9, 3, 18, 30),
        photos: const ['https://cdn/r.jpg'],
      );
      expect(review.isMine, isTrue);
      expect(adapter.last.data, {
        'rating': 5,
        'worthIt': true,
        'text': 'Great',
        'visitedOn': '2026-09-03',
        'photos': ['https://cdn/r.jpg'],
      });

      await repository.deleteReview('p1');
      expect(adapter.last.method, 'DELETE');
    });

    test('an out-of-range rating is rejected before calling the API', () async {
      await serve((_) => (status: 500, body: null));
      expect(
        () => SubmitPlaceReview(repository)(placeId: 'p1', rating: 0, worthIt: true, text: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(adapter.requests, isEmpty);
    });

    test('API errors surface as AppException with the server message', () async {
      await serve((_) => (
            status: 409,
            body: apiError('CANNOT_REVIEW_OWN_PLACE', "You can't review a place you shared."),
          ));
      await expectLater(
        repository.submitReview(placeId: 'p1', rating: 5, worthIt: true, text: ''),
        throwsA(isA<AppException>().having((e) => e.message, 'message', "You can't review a place you shared.")),
      );
    });
  });
}
