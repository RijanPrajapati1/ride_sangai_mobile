/// A rider's review of a place: stars, "was it worth it?", and their story.
class PlaceReview {
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

  const PlaceReview({
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
}
