import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:yatrix/core/enums/dashboard_category.dart';
import 'package:yatrix/core/enums/place_category.dart';
import 'package:yatrix/core/errors/app_exception.dart';
import 'package:yatrix/core/network/api_client.dart';
import 'package:yatrix/core/network/dio_factory.dart';
import 'package:yatrix/core/storage/token_storage.dart';
import 'package:yatrix/core/utils/geo.dart';
import 'package:yatrix/features/explore/data/dto/place_dto.dart';
import 'package:yatrix/features/explore/data/dto/place_review_dto.dart';
import 'package:yatrix/features/explore/domain/entities/place.dart';
import 'package:yatrix/features/explore/domain/entities/place_review.dart';
import 'package:yatrix/features/explore/domain/repositories/place_repository.dart';

/// Shared helpers for the Explore tests (not a test file itself).

/// Answers requests from a handler instead of the network, and records them.
class FakeAdapter implements HttpClientAdapter {
  final ({int status, Object? body}) Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final reply = handler(options);
    return ResponseBody.fromString(
      reply.body == null ? '' : jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  RequestOptions get last => requests.last;

  @override
  void close({bool force = false}) {}
}

/// An [ApiClient] signed in with a valid token, talking to [adapter].
Future<ApiClient> fakeApiClient(FakeAdapter adapter) async {
  FlutterSecureStorage.setMockInitialValues({});
  final storage = TokenStorage(const FlutterSecureStorage());
  await storage.saveTokens(AuthTokens(
    accessToken: 'access',
    refreshToken: 'refresh',
    accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
  ));
  return ApiClient(DioFactory.create(
    tokenStorage: storage,
    onSessionEnded: () {},
    baseUrl: 'http://test/api/v1',
    adapter: adapter,
  ));
}

Map<String, dynamic> apiError(String code, String message) => {
      'error': {'code': code, 'message': message},
      'requestId': 'test',
    };

Map<String, dynamic> page(List<Map<String, dynamic>> items, [String? nextCursor]) =>
    {'items': items, 'nextCursor': nextCursor};

/// A place exactly as the API returns it.
Map<String, dynamic> placeJson({
  String id = 'p1',
  String name = 'Kakani Viewpoint',
  String category = 'viewpoint',
  double? distanceKm = 12.3,
  bool isSaved = false,
  bool isMine = false,
  Map<String, dynamic>? myReview,
  double? averageRating = 4.5,
  int? worthItPercent = 100,
  String? tips,
}) =>
    {
      'id': id,
      'name': name,
      'description': 'Views of the Ganesh Himal.',
      'category': category,
      'latitude': 27.804,
      'longitude': 85.2546,
      'locationName': 'Kakani, Nuwakot',
      'photos': ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
      'coverImageUrl': 'https://example.com/a.jpg',
      'activities': ['riding', 'cycling'],
      'bestTime': 'October to December',
      'tips': tips,
      'entryFee': 'Free',
      'averageRating': averageRating,
      'reviewCount': averageRating == null ? 0 : 2,
      'worthItPercent': worthItPercent,
      'saveCount': 3,
      'distanceKm': distanceKm,
      'authorId': 'u2',
      'authorName': 'Nischal Karki',
      'authorAvatarUrl': '',
      'isMine': isMine,
      'isSaved': isSaved,
      'myReview': myReview,
      'createdAt': '2026-10-01T10:00:00.000Z',
    };

/// A review exactly as the API returns it.
Map<String, dynamic> reviewJson({String id = 'r1', String placeId = 'p1', bool worthIt = true, int rating = 4}) => {
      'id': id,
      'placeId': placeId,
      'userId': 'u3',
      'userName': 'Priya Shrestha',
      'userAvatarUrl': '',
      'rating': rating,
      'worthIt': worthIt,
      'text': 'Lovely in the morning.',
      'visitedOn': '2026-09-28',
      'photos': ['https://example.com/r.jpg'],
      'createdAt': '2026-10-02T08:00:00.000Z',
      'updatedAt': '2026-10-02T09:00:00.000Z',
      'isMine': false,
    };

Place placeFromJson(Map<String, dynamic> json) => PlaceDto.fromJson(json).toEntity();

/// In-memory [PlaceRepository] for widget tests: filters like the API does.
class FakePlaceRepository implements PlaceRepository {
  final List<Place> places;
  final Map<String, List<PlaceReview>> reviews;
  final Set<String> saved;
  final queries = <PlaceQuery>[];

  FakePlaceRepository({required this.places, this.reviews = const {}, Set<String>? saved}) : saved = saved ?? {};

  static FakePlaceRepository seeded() => FakePlaceRepository(
        places: [
          placeFromJson(placeJson(id: 'p1', name: 'Kakani Viewpoint', distanceKm: 12.3)),
          placeFromJson(placeJson(id: 'p2', name: 'Taudaha Lake', category: 'lake', distanceKm: 8.1)),
          placeFromJson(placeJson(
            id: 'p3',
            name: 'Sundarijal Waterfall',
            category: 'waterfall',
            distanceKm: 15,
            averageRating: 3.0,
            worthItPercent: 50,
            tips: 'Go in monsoon.',
            isSaved: true,
          )),
        ],
        reviews: {
          'p3': [
            PlaceReviewDto.fromJson(reviewJson(id: 'r1', placeId: 'p3', worthIt: false, rating: 2)).toEntity(),
            PlaceReviewDto.fromJson(reviewJson(id: 'r2', placeId: 'p3', rating: 4)).toEntity(),
          ],
        },
        saved: {'p3'},
      );

  Place _find(String id) =>
      places.firstWhere((p) => p.id == id, orElse: () => throw const NotFoundException('This place no longer exists.'));

  @override
  Future<List<Place>> getPlaces(PlaceQuery query) async {
    queries.add(query);
    return places
        .where((p) => query.category == null || p.category == query.category)
        .where((p) => query.activity == null || p.activities.contains(query.activity))
        .where((p) => query.query.isEmpty || p.name.toLowerCase().contains(query.query.toLowerCase()))
        .toList();
  }

  @override
  Future<Place> getPlaceById(String id, {GeoPoint? from}) async => _find(id);

  @override
  Future<List<PlaceReview>> getReviews(String placeId) async => reviews[placeId] ?? const [];

  @override
  Future<List<Place>> getSavedPlaces({GeoPoint? from}) async => places.where((p) => saved.contains(p.id)).toList();

  @override
  Future<List<Place>> getPlacesByUser(String userId, {GeoPoint? from}) async =>
      places.where((p) => p.authorId == userId).toList();

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
  }) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

  @override
  Future<void> savePlace(String placeId) async => saved.add(placeId);

  @override
  Future<void> unsavePlace(String placeId) async => saved.remove(placeId);

  @override
  Future<PlaceReview> submitReview({
    required String placeId,
    required int rating,
    required bool worthIt,
    required String text,
    DateTime? visitedOn,
    List<String> photos = const [],
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteReview(String placeId) async {}

  @override
  Future<void> deletePlace(String placeId) async => places.removeWhere((p) => p.id == placeId);
}
