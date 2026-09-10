class RideParticipant {
  final String id;
  final String userId;
  final String name;
  final String avatarUrl;
  final DateTime joinedAt;

  const RideParticipant({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.joinedAt,
  });
}
