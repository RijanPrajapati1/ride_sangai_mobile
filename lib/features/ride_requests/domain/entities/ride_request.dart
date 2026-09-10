import '../../../../core/enums/ride_enums.dart';

class RideRequest {
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

  const RideRequest({
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

  RideRequest copyWith({RideRequestStatus? status}) {
    return RideRequest(
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
}
