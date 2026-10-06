import '../../../../core/enums/ride_enums.dart';
import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/ride_request.dart';

/// Matches the API's `RideRequest`.
class RideRequestDto {
  final String id;
  final String rideId;
  final String rideTitle;
  final DateTime rideDate;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String userBio;
  final String? message;
  final ExperienceLevel experienceLevel;
  final DateTime requestedAt;
  final RideRequestStatus status;
  final String? declineReason;
  final DateTime? decidedAt;

  const RideRequestDto({
    required this.id,
    required this.rideId,
    required this.rideTitle,
    required this.rideDate,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.userBio,
    required this.experienceLevel,
    required this.requestedAt,
    required this.status,
    this.message,
    this.declineReason,
    this.decidedAt,
  });

  factory RideRequestDto.fromJson(Map<String, dynamic> json) => RideRequestDto(
        id: json['id'] as String,
        rideId: json['rideId'] as String,
        rideTitle: json['rideTitle'] as String? ?? '',
        rideDate: parseDate(json['rideDate']),
        userId: json['userId'] as String,
        userName: json['userName'] as String? ?? '',
        userAvatarUrl: json['userAvatarUrl'] as String? ?? '',
        userBio: json['userBio'] as String? ?? '',
        message: json['message'] as String?,
        experienceLevel: enumByName(ExperienceLevel.values, json['experienceLevel'], ExperienceLevel.beginner),
        requestedAt: parseDate(json['requestedAt']),
        status: enumByName(RideRequestStatus.values, json['status'], RideRequestStatus.pending),
        declineReason: json['declineReason'] as String?,
        decidedAt: parseDateOrNull(json['decidedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rideId': rideId,
        'rideTitle': rideTitle,
        'rideDate': toApiDate(rideDate),
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'userBio': userBio,
        'message': message,
        'experienceLevel': experienceLevel.name,
        'requestedAt': toApiDate(requestedAt),
        'status': status.name,
        'declineReason': declineReason,
        'decidedAt': decidedAt == null ? null : toApiDate(decidedAt!),
      };

  RideRequest toEntity() => RideRequest(
        id: id,
        rideId: rideId,
        rideTitle: rideTitle,
        rideDate: rideDate,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        userBio: userBio,
        message: message,
        experienceLevel: experienceLevel,
        requestedAt: requestedAt,
        status: status,
        declineReason: declineReason,
        decidedAt: decidedAt,
      );
}
