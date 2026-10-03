import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../domain/entities/place.dart';

/// Data-layer shape of a place. `fromJson`/`toJson` match the API's
/// `/api/v1/places` responses, so a remote data source can reuse this DTO.
class PlaceDto {
  final String id;
  final String name;
  final String description;
  final PlaceCategory category;
  final double latitude;
  final double longitude;
  final String locationName;
  final List<String> photos;
  final List<DashboardCategory> activities;
  final String? bestTime;
  final String? tips;
  final String? entryFee;
  final double? averageRating;
  final int reviewCount;
  final int? worthItPercent;
  final int saveCount;
  final double? distanceKm;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final bool isMine;
  final bool isSaved;
  final MyPlaceReview? myReview;
  final DateTime createdAt;

  const PlaceDto({
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

  factory PlaceDto.fromJson(Map<String, dynamic> json) {
    final myReview = json['myReview'] as Map<String, dynamic>?;
    return PlaceDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: PlaceCategory.values.byName(json['category'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['locationName'] as String,
      photos: List<String>.from(json['photos'] as List? ?? const []),
      activities: [
        for (final value in json['activities'] as List? ?? const []) DashboardCategory.values.byName(value as String),
      ],
      bestTime: json['bestTime'] as String?,
      tips: json['tips'] as String?,
      entryFee: json['entryFee'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
      worthItPercent: json['worthItPercent'] as int?,
      saveCount: json['saveCount'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String? ?? '',
      isMine: json['isMine'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
      myReview: myReview == null
          ? null
          : MyPlaceReview(
              id: myReview['id'] as String,
              rating: myReview['rating'] as int,
              worthIt: myReview['worthIt'] as bool,
            ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Request body for POST /places.
  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'description': description,
        'category': category.name,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'photos': photos,
        'activities': [for (final a in activities) a.name],
        'bestTime': bestTime,
        'tips': tips,
        'entryFee': entryFee,
      };

  PlaceDto copyWith({
    double? averageRating,
    int? reviewCount,
    int? worthItPercent,
    int? saveCount,
    double? distanceKm,
    bool? isSaved,
    MyPlaceReview? myReview,
    bool clearMyReview = false,
    bool clearRating = false,
  }) {
    return PlaceDto(
      id: id,
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
      averageRating: clearRating ? null : (averageRating ?? this.averageRating),
      reviewCount: reviewCount ?? this.reviewCount,
      worthItPercent: clearRating ? null : (worthItPercent ?? this.worthItPercent),
      saveCount: saveCount ?? this.saveCount,
      distanceKm: distanceKm ?? this.distanceKm,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      isMine: isMine,
      isSaved: isSaved ?? this.isSaved,
      myReview: clearMyReview ? null : (myReview ?? this.myReview),
      createdAt: createdAt,
    );
  }

  Place toEntity() => Place(
        id: id,
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
        averageRating: averageRating,
        reviewCount: reviewCount,
        worthItPercent: worthItPercent,
        saveCount: saveCount,
        distanceKm: distanceKm,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        isMine: isMine,
        isSaved: isSaved,
        myReview: myReview,
        createdAt: createdAt,
      );
}
