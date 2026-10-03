import '../../domain/entities/place_review.dart';

/// Data-layer shape of a review; `fromJson` matches the API's review responses.
class PlaceReviewDto {
  final String id;
  final String placeId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final int rating;
  final bool worthIt;
  final String text;
  final DateTime? visitedOn;
  final List<String> photos;
  final DateTime createdAt;
  final bool isMine;

  const PlaceReviewDto({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.worthIt,
    required this.text,
    this.visitedOn,
    this.photos = const [],
    required this.createdAt,
    this.isMine = false,
  });

  factory PlaceReviewDto.fromJson(Map<String, dynamic> json) => PlaceReviewDto(
        id: json['id'] as String,
        placeId: json['placeId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userAvatarUrl: json['userAvatarUrl'] as String? ?? '',
        rating: json['rating'] as int,
        worthIt: json['worthIt'] as bool,
        text: json['text'] as String? ?? '',
        visitedOn: json['visitedOn'] == null ? null : DateTime.parse(json['visitedOn'] as String),
        photos: List<String>.from(json['photos'] as List? ?? const []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isMine: json['isMine'] as bool? ?? false,
      );

  /// Request body for PUT /places/:id/review.
  Map<String, dynamic> toRequestJson() => {
        'rating': rating,
        'worthIt': worthIt,
        'text': text,
        'visitedOn': visitedOn?.toIso8601String().substring(0, 10),
        'photos': photos,
      };

  PlaceReview toEntity() => PlaceReview(
        id: id,
        placeId: placeId,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        rating: rating,
        worthIt: worthIt,
        text: text,
        visitedOn: visitedOn,
        photos: photos,
        createdAt: createdAt,
        isMine: isMine,
      );
}
