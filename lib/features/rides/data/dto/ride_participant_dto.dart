import '../../domain/entities/ride_participant.dart';

class RideParticipantDto {
  final String id;
  final String rideId;
  final String userId;
  final String name;
  final String avatarUrl;
  final DateTime joinedAt;

  RideParticipantDto({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.joinedAt,
  });

  RideParticipant toEntity() => RideParticipant(
        id: id,
        userId: userId,
        name: name,
        avatarUrl: avatarUrl,
        joinedAt: joinedAt,
      );
}
