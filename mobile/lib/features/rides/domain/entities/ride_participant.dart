import '../../../../core/enums/ride_enums.dart';

class RideParticipant {
  final String id;
  final String userId;
  final String name;
  final String avatarUrl;

  /// [RideJoinStatus.organizer], [RideJoinStatus.approved] or [RideJoinStatus.pending].
  final RideJoinStatus status;
  final DateTime joinedAt;

  const RideParticipant({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.status,
    required this.joinedAt,
  });
}
