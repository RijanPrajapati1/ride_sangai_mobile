import '../../../../core/constants/app_constants.dart';
import '../../../../core/dummy/dummy_people.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/geo.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../dto/place_dto.dart';
import '../dto/place_review_dto.dart';

/// In-memory stand-in for the Explore API (`/api/v1/places`). Seeded with the
/// same places as the server's demo data. A `PlaceRemoteDataSource` can
/// replace it using the DTOs' `fromJson`.
class PlaceLocalDataSource {
  PlaceLocalDataSource() {
    _places = _seedPlaces();
    _reviews = _seedReviews();
    for (final id in _places.keys.toList()) {
      _refreshAggregates(id);
    }
  }

  late final Map<String, PlaceDto> _places;
  late final Map<String, List<PlaceReviewDto>> _reviews;
  final Set<String> _savedByMe = {'pl_002', 'pl_005', 'pl_007'};
  int _placeSeq = 100;
  int _reviewSeq = 100;

  Future<List<PlaceDto>> getPlaces(PlaceQuery query) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    final text = query.query.trim().toLowerCase();
    var places = _places.values.map((p) => _forViewer(p, query.from)).where((p) {
      if (query.category != null && p.category != query.category) return false;
      if (query.activity != null && !p.activities.contains(query.activity)) return false;
      if (text.isNotEmpty &&
          !p.name.toLowerCase().contains(text) &&
          !p.locationName.toLowerCase().contains(text)) {
        return false;
      }
      if (query.radiusKm != null && p.distanceKm != null && p.distanceKm! > query.radiusKm!) return false;
      return true;
    }).toList();

    switch (query.sort) {
      case PlaceSort.nearest:
        places.sort((a, b) => (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity));
      case PlaceSort.topRated:
        places.sort((a, b) {
          final byRating = (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
          return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
        });
      case PlaceSort.newest:
        places.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return places;
  }

  Future<PlaceDto> getPlaceById(String id, {GeoPoint? from}) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    return _forViewer(_require(id), from);
  }

  Future<List<PlaceReviewDto>> getReviews(String placeId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _require(placeId);
    return List.of(_reviews[placeId] ?? const <PlaceReviewDto>[])..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<PlaceDto>> getSavedPlaces({GeoPoint? from}) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    return [
      for (final id in _savedByMe)
        if (_places[id] != null) _forViewer(_places[id]!, from),
    ];
  }

  Future<PlaceDto> sharePlace(PlaceDto draft) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    final id = 'pl_${_placeSeq++}';
    final place = PlaceDto(
      id: id,
      name: draft.name,
      description: draft.description,
      category: draft.category,
      latitude: draft.latitude,
      longitude: draft.longitude,
      locationName: draft.locationName,
      photos: draft.photos,
      activities: draft.activities,
      bestTime: draft.bestTime,
      tips: draft.tips,
      entryFee: draft.entryFee,
      authorId: DummyPeople.me.id,
      authorName: DummyPeople.me.name,
      authorAvatarUrl: DummyPeople.me.avatarUrl,
      createdAt: DateTime.now(),
    );
    _places[id] = place;
    _reviews[id] = [];
    return _forViewer(place, null);
  }

  Future<void> savePlace(String placeId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _require(placeId);
    if (_savedByMe.add(placeId)) _bumpSaves(placeId, 1);
  }

  Future<void> unsavePlace(String placeId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _require(placeId);
    if (_savedByMe.remove(placeId)) _bumpSaves(placeId, -1);
  }

  Future<PlaceReviewDto> submitReview({
    required String placeId,
    required int rating,
    required bool worthIt,
    required String text,
    DateTime? visitedOn,
  }) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final place = _require(placeId);
    if (place.authorId == DummyPeople.me.id) {
      throw const ValidationException('You shared this place, so you cannot review it.');
    }
    final reviews = _reviews.putIfAbsent(placeId, () => []);
    final existing = reviews.indexWhere((r) => r.userId == DummyPeople.me.id);
    final review = PlaceReviewDto(
      id: existing >= 0 ? reviews[existing].id : 'pr_${_reviewSeq++}',
      placeId: placeId,
      userId: DummyPeople.me.id,
      userName: DummyPeople.me.name,
      userAvatarUrl: DummyPeople.me.avatarUrl,
      rating: rating,
      worthIt: worthIt,
      text: text,
      visitedOn: visitedOn,
      createdAt: existing >= 0 ? reviews[existing].createdAt : DateTime.now(),
      isMine: true,
    );
    if (existing >= 0) {
      reviews[existing] = review;
    } else {
      reviews.add(review);
    }
    _refreshAggregates(placeId);
    return review;
  }

  Future<void> deleteReview(String placeId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _require(placeId);
    final reviews = _reviews[placeId];
    final before = reviews?.length ?? 0;
    reviews?.removeWhere((r) => r.userId == DummyPeople.me.id);
    if ((reviews?.length ?? 0) == before) throw const NotFoundException('You have not reviewed this place.');
    _refreshAggregates(placeId);
  }

  Future<void> deletePlace(String placeId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _places.remove(placeId);
    _reviews.remove(placeId);
    _savedByMe.remove(placeId);
  }

  // --- helpers ------------------------------------------------------------------

  PlaceDto _require(String id) {
    final place = _places[id];
    if (place == null) throw const NotFoundException('This place could not be found.');
    return place;
  }

  /// Fills in the per-viewer fields the API computes: distance, saved, my review.
  PlaceDto _forViewer(PlaceDto place, GeoPoint? from) {
    final mine = (_reviews[place.id] ?? const <PlaceReviewDto>[]).where((r) => r.userId == DummyPeople.me.id);
    final myReview = mine.isEmpty ? null : MyPlaceReview(id: mine.first.id, rating: mine.first.rating, worthIt: mine.first.worthIt);
    return PlaceDto(
      id: place.id,
      name: place.name,
      description: place.description,
      category: place.category,
      latitude: place.latitude,
      longitude: place.longitude,
      locationName: place.locationName,
      photos: place.photos,
      activities: place.activities,
      bestTime: place.bestTime,
      tips: place.tips,
      entryFee: place.entryFee,
      averageRating: place.averageRating,
      reviewCount: place.reviewCount,
      worthItPercent: place.worthItPercent,
      saveCount: place.saveCount,
      distanceKm: from == null ? null : distanceKm(from, GeoPoint(place.latitude, place.longitude)),
      authorId: place.authorId,
      authorName: place.authorName,
      authorAvatarUrl: place.authorAvatarUrl,
      isMine: place.authorId == DummyPeople.me.id,
      isSaved: _savedByMe.contains(place.id),
      myReview: myReview,
      createdAt: place.createdAt,
    );
  }

  void _refreshAggregates(String placeId) {
    final place = _places[placeId];
    if (place == null) return;
    final reviews = _reviews[placeId] ?? const <PlaceReviewDto>[];
    if (reviews.isEmpty) {
      _places[placeId] = place.copyWith(reviewCount: 0, clearRating: true);
      return;
    }
    final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
    final worth = reviews.where((r) => r.worthIt).length;
    _places[placeId] = place.copyWith(
      averageRating: double.parse((total / reviews.length).toStringAsFixed(1)),
      reviewCount: reviews.length,
      worthItPercent: (worth * 100 / reviews.length).round(),
    );
  }

  void _bumpSaves(String placeId, int delta) {
    final place = _places[placeId];
    if (place == null) return;
    _places[placeId] = place.copyWith(saveCount: (place.saveCount + delta).clamp(0, 1 << 31));
  }

  // --- seed (matches server/prisma/seed.ts) -------------------------------------

  static String _photo(String seed) => 'https://picsum.photos/seed/$seed/900/600';

  Map<String, PlaceDto> _seedPlaces() {
    final now = DateTime.now();
    PlaceDto place({
      required String id,
      required DummyPerson author,
      required String name,
      required PlaceCategory category,
      required double lat,
      required double lng,
      required String locationName,
      required List<DashboardCategory> activities,
      required String description,
      String? bestTime,
      String? tips,
      String? entryFee,
      required String image,
      required int daysAgo,
      int saveCount = 0,
    }) {
      return PlaceDto(
        id: id,
        name: name,
        description: description,
        category: category,
        latitude: lat,
        longitude: lng,
        locationName: locationName,
        photos: [_photo(image), _photo('$image-2')],
        activities: activities,
        bestTime: bestTime,
        tips: tips,
        entryFee: entryFee,
        saveCount: saveCount,
        authorId: author.id,
        authorName: author.name,
        authorAvatarUrl: author.avatarUrl,
        createdAt: now.subtract(Duration(days: daysAgo)),
      );
    }

    final places = [
      place(
        id: 'pl_001',
        author: DummyPeople.sabina,
        name: 'Taudaha Lake',
        category: PlaceCategory.lake,
        lat: 27.6476,
        lng: 85.2813,
        locationName: 'Taudaha, Kirtipur',
        activities: [DashboardCategory.cycling, DashboardCategory.hiking],
        description:
            'A quiet lake just past Chobhar where migratory birds stop in winter. Locals say it is where Manjushree '
            'drained the valley lake. Easy flat loop around the water.',
        bestTime: 'November to February (migratory birds)',
        tips: 'Come before 8am for the birds and soft light. Tea shops on the Dakshinkali road.',
        entryFee: 'Free',
        image: 'taudaha-lake',
        daysAgo: 60,
        saveCount: 1,
      ),
      place(
        id: 'pl_002',
        author: DummyPeople.kabita,
        name: 'Champadevi Viewpoint',
        category: PlaceCategory.viewpoint,
        lat: 27.6243,
        lng: 85.2512,
        locationName: 'Champadevi, Pharping',
        activities: [DashboardCategory.hiking],
        description:
            'A ridge-top shrine with one of the widest Himalayan panoramas from the valley — Ganesh Himal to Langtang '
            'on a clear day. The forest trail from Pharping is shady most of the way.',
        bestTime: 'October to December for clear Himalayan views',
        tips: 'Start from Hattiban Resort road; carry water, there is nothing at the top.',
        entryFee: 'Free',
        image: 'champadevi',
        daysAgo: 45,
        saveCount: 1,
      ),
      place(
        id: 'pl_003',
        author: DummyPeople.anita,
        name: 'Sundarijal Waterfall',
        category: PlaceCategory.waterfall,
        lat: 27.7631,
        lng: 85.4256,
        locationName: 'Sundarijal, Shivapuri National Park',
        activities: [DashboardCategory.hiking, DashboardCategory.trekking],
        description:
            'Stone stairs beside the old water pipeline lead to a series of cascades inside the national park. '
            'Great first stop on the Chisapani trek.',
        bestTime: 'July to September (monsoon flow)',
        tips: 'Steps get slippery in monsoon — wear proper shoes.',
        entryFee: 'Park entry fee',
        image: 'sundarijal-fall',
        daysAgo: 40,
        saveCount: 1,
      ),
      place(
        id: 'pl_004',
        author: DummyPeople.nischal,
        name: 'Kakani Viewpoint',
        category: PlaceCategory.viewpoint,
        lat: 27.804,
        lng: 85.2546,
        locationName: 'Kakani, Nuwakot',
        activities: [DashboardCategory.riding, DashboardCategory.cycling],
        description:
            'Strawberry farms, a British-era bungalow and a front-row view of the Ganesh Himal range, an easy hour '
            'out of Kathmandu on a twisty road bikers love.',
        bestTime: 'Clear winter mornings',
        tips: 'Try the fresh strawberries in spring. The road is narrow after Kaulethana — ride carefully.',
        entryFee: 'Free',
        image: 'kakani',
        daysAgo: 30,
        saveCount: 1,
      ),
      place(
        id: 'pl_005',
        author: DummyPeople.roshani,
        name: 'Namobuddha Monastery',
        category: PlaceCategory.temple,
        lat: 27.5714,
        lng: 85.585,
        locationName: 'Namobuddha, Kavre',
        activities: [DashboardCategory.cycling, DashboardCategory.riding, DashboardCategory.hiking],
        description:
            'A golden hilltop monastery with a stupa where, legend says, the prince gave his body to a starving '
            'tigress. Prayer flags everywhere and a peaceful vibe.',
        bestTime: 'Year round; sunrise is magical',
        tips: 'Dress modestly and walk clockwise around the stupa. The monastery restaurant serves a great dal bhat.',
        entryFee: 'Free',
        image: 'namobuddha',
        daysAgo: 25,
        saveCount: 1,
      ),
      place(
        id: 'pl_006',
        author: DummyPeople.priya,
        name: 'Panauti Old Town',
        category: PlaceCategory.heritage,
        lat: 27.5847,
        lng: 85.5208,
        locationName: 'Panauti, Kavre',
        activities: [DashboardCategory.cycling, DashboardCategory.riding],
        description:
            'A Newar town at the meeting of two rivers with Indreshwar Mahadev, one of the oldest pagoda temples '
            'in Nepal, and brick lanes that feel untouched.',
        bestTime: 'During Jatra in June, or any quiet weekday',
        tips: 'Stay for a homestay dinner; locals will show you the hidden courtyards.',
        entryFee: 'Small heritage fee for foreigners',
        image: 'panauti',
        daysAgo: 20,
      ),
      place(
        id: 'pl_007',
        author: DummyPeople.dipesh,
        name: 'Bagdwar — Source of the Bagmati',
        category: PlaceCategory.trail,
        lat: 27.818,
        lng: 85.392,
        locationName: 'Shivapuri National Park',
        activities: [DashboardCategory.trekking, DashboardCategory.hiking],
        description:
            'A steep forest trail to the spring where the holy Bagmati river begins, flowing out of a stone tiger '
            'mouth. Most people never know it is this close to the city.',
        bestTime: 'October to April',
        tips: 'Go with a group — the upper forest is quiet. Budhanilkantha gate is the easiest start.',
        entryFee: 'Park entry fee',
        image: 'bagdwar',
        daysAgo: 12,
        saveCount: 1,
      ),
      place(
        id: 'pl_008',
        author: DummyPeople.suresh,
        name: 'Lakuri Bhanjyang Tea Stop',
        category: PlaceCategory.cafe,
        lat: 27.6045,
        lng: 85.4268,
        locationName: 'Lakuri Bhanjyang, Lalitpur',
        activities: [DashboardCategory.cycling, DashboardCategory.riding],
        description:
            'The classic climb out of Lubhu ends at a ridge with a few tea shops and views over the whole valley. '
            'Every road cyclist in Kathmandu stops here.',
        bestTime: 'Sunrise or sunset',
        tips: 'Order the milk tea and sel roti. Descent to Panauti side is fast and fun.',
        image: 'lakuri',
        daysAgo: 6,
      ),
    ];
    return {for (final p in places) p.id: p};
  }

  Map<String, List<PlaceReviewDto>> _seedReviews() {
    final now = DateTime.now();
    var seq = 1;
    PlaceReviewDto review(String placeId, DummyPerson author, int rating, bool worthIt, String text, int daysAgo) {
      return PlaceReviewDto(
        id: 'pr_${(seq++).toString().padLeft(3, '0')}',
        placeId: placeId,
        userId: author.id,
        userName: author.name,
        userAvatarUrl: author.avatarUrl,
        rating: rating,
        worthIt: worthIt,
        text: text,
        visitedOn: now.subtract(Duration(days: daysAgo + 1)),
        createdAt: now.subtract(Duration(days: daysAgo)),
        isMine: author.id == DummyPeople.me.id,
      );
    }

    final reviews = [
      review('pl_001', DummyPeople.me, 5, true, 'Perfect short ride from Kathmandu. Saw so many ducks!', 20),
      review('pl_001', DummyPeople.priya, 4, true, 'Lovely in the morning, gets busy on Saturdays.', 15),
      review('pl_002', DummyPeople.sabina, 5, true, 'Best mountain view near the city. Worth every step.', 10),
      review('pl_002', DummyPeople.bibek, 3, true, 'Long climb for a beginner, but the view paid off.', 8),
      review('pl_003', DummyPeople.aarav, 4, true, 'Go in monsoon, the falls are huge.', 12),
      review('pl_003', DummyPeople.roshani, 2, false, 'Not much water in spring, honestly skip it then.', 5),
      review('pl_004', DummyPeople.dipesh, 5, true, 'Amazing ride, amazing view, amazing strawberries.', 9),
      review('pl_004', DummyPeople.me, 4, true, 'Great Sunday ride. Roads are a bit broken near the top.', 4),
      review('pl_005', DummyPeople.suresh, 5, true, 'Sunrise here is unreal. Stay overnight if you can.', 7),
      review('pl_006', DummyPeople.kabita, 5, true, 'Felt like going back in time. Very friendly locals.', 3),
      review('pl_008', DummyPeople.nischal, 4, true, 'Tough climb, best tea.', 2),
    ];
    final byPlace = <String, List<PlaceReviewDto>>{};
    for (final r in reviews) {
      byPlace.putIfAbsent(r.placeId, () => []).add(r);
    }
    return byPlace;
  }
}
