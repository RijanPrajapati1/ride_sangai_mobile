/// A rider in someone's followers or following list.
class FollowConnection {
  final String id;
  final String name;
  final String avatarUrl;
  final String location;

  /// Whether the signed-in user follows this rider.
  final bool isFollowing;
  final DateTime followedAt;

  const FollowConnection({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.location,
    required this.isFollowing,
    required this.followedAt,
  });
}
