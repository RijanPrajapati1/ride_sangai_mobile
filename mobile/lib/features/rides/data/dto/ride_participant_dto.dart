import '../../../../core/enums/ride_enums.dart';
import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/ride_participant.dart';

/// Matches the API's `RideParticipant` (`GET /rides/:id/participants`).
class RideParticipantDto {
  final String id;
  final String rideId;
  final String userId;
  final String name;
  final String avatarUrl;
  final RideJoinStatus status;
  final DateTime joinedAt;

  const RideParticipantDto({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.status,
    required this.joinedAt,
  });

  factory RideParticipantDto.fromJson(Map<String, dynamic> json) => RideParticipantDto(
        id: json['id'] as String,
        rideId: json['rideId'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        status: enumByName(RideJoinStatus.values, json['status'], RideJoinStatus.approved),
        joinedAt: parseDate(json['joinedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rideId': rideId,
        'userId': userId,
        'name': name,
        'avatarUrl': avatarUrl,
        'status': status.name,
        'joinedAt': toApiDate(joinedAt),
      };

  RideParticipant toEntity() => RideParticipant(
        id: id,
        userId: userId,
        name: name,
        avatarUrl: avatarUrl,
        status: status,
        joinedAt: joinedAt,
      );
}
