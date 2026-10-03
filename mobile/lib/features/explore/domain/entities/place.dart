import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/utils/geo.dart';

/// The viewer's own rating of a place, if they reviewed it.
class MyPlaceReview {
  final String id;
  final int rating;
  final bool worthIt;

  const MyPlaceReview({required this.id, required this.rating, required this.worthIt});
}

/// A spot worth visiting — often a hidden gem — shared by someone who knows it.
class Place {
  final String id;
  final String name;
  final String description;
  final PlaceCategory category;
  final double latitude;
  final double longitude;

  /// Human-readable place, e.g. "Near Nagarkot, Bhaktapur".
  final String locationName;
  final List<String> photos;

  /// Dashboards the place suits (cycling, trekking, hiking, riding).
  final List<DashboardCategory> activities;
  final String? bestTime;
  final String? tips;
  final String? entryFee;

  /// 1–5 with one decimal; null until someone reviews it.
  final double? averageRating;
  final int reviewCount;

  /// Share of reviewers who said it was worth the trip; null until reviewed.
  final int? worthItPercent;
  final int saveCount;

  /// Distance from the rider, when their location is known.
  final double? distanceKm;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final bool isMine;
  final bool isSaved;
  final MyPlaceReview? myReview;
  final DateTime createdAt;

  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.photos,
    required this.activities,
    this.bestTime,
    this.tips,
    this.entryFee,
    this.averageRating,
    this.reviewCount = 0,
    this.worthItPercent,
    this.saveCount = 0,
    this.distanceKm,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    this.isMine = false,
    this.isSaved = false,
    this.myReview,
    required this.createdAt,
  });

  GeoPoint get point => GeoPoint(latitude, longitude);

  String? get coverImageUrl => photos.isEmpty ? null : photos.first;
}
