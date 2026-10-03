import '../../../../core/enums/ride_enums.dart';
import '../../domain/entities/ride_request.dart';

class RideRequestDto {
  final String id;
  final String rideId;
  final String rideTitle;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String userBio;
  final ExperienceLevel experienceLevel;
  final DateTime requestedAt;
  final RideRequestStatus status;

  RideRequestDto({
    required this.id,
    required this.rideId,
    required this.rideTitle,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.userBio,
    required this.experienceLevel,
    required this.requestedAt,
    this.status = RideRequestStatus.pending,
  });

  RideRequestDto copyWith({RideRequestStatus? status}) {
    return RideRequestDto(
      id: id,
      rideId: rideId,
      rideTitle: rideTitle,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      userBio: userBio,
      experienceLevel: experienceLevel,
      requestedAt: requestedAt,
      status: status ?? this.status,
    );
  }

  RideRequest toEntity() => RideRequest(
        id: id,
        rideId: rideId,
        rideTitle: rideTitle,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        userBio: userBio,
        experienceLevel: experienceLevel,
        requestedAt: requestedAt,
        status: status,
      );
}
