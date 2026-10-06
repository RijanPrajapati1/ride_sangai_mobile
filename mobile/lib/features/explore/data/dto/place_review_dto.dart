import '../../../../core/utils/json_parsing.dart';
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
  final DateTime? updatedAt;
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
    this.updatedAt,
    this.isMine = false,
  });

  factory PlaceReviewDto.fromJson(Map<String, dynamic> json) => PlaceReviewDto(
        id: json['id'] as String,
        placeId: json['placeId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String? ?? '',
        userAvatarUrl: json['userAvatarUrl'] as String? ?? '',
        rating: json['rating'] as int,
        worthIt: json['worthIt'] as bool,
        text: json['text'] as String? ?? '',
        // A plain calendar date ("2026-10-01"), so no time-zone shift.
        visitedOn: json['visitedOn'] == null ? null : DateTime.parse(json['visitedOn'] as String),
        photos: stringList(json['photos']),
        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDateOrNull(json['updatedAt']),
        isMine: json['isMine'] as bool? ?? false,
      );

  /// The full API `PlaceReview` shape.
  Map<String, dynamic> toJson() => {
        'id': id,
        'placeId': placeId,
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'rating': rating,
        'worthIt': worthIt,
        'text': text,
        'visitedOn': visitedOn == null ? null : formatApiDay(visitedOn!),
        'photos': photos,
        'createdAt': toApiDate(createdAt),
        'updatedAt': toApiDate(updatedAt ?? createdAt),
        'isMine': isMine,
      };

  /// Request body for PUT /places/:id/review.
  Map<String, dynamic> toRequestJson() => {
        'rating': rating,
        'worthIt': worthIt,
        'text': text,
        'visitedOn': visitedOn == null ? null : formatApiDay(visitedOn!),
        'photos': photos,
      };

  /// `YYYY-MM-DD` for the API's `format: date` fields.
  static String formatApiDay(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
