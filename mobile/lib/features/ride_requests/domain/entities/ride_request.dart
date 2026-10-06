import '../../../../core/enums/ride_enums.dart';

class RideRequest {
  final String id;
  final String rideId;
  final String rideTitle;
  final DateTime? rideDate;
  final String userId;
  final String userName;
  final String userAvatarUrl;

  /// The rider's note with the request, or their profile bio.
  final String userBio;

  /// The note the rider sent with the request, if any.
  final String? message;
  final ExperienceLevel experienceLevel;
  final DateTime requestedAt;
  final RideRequestStatus status;
  final String? declineReason;
  final DateTime? decidedAt;

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
    this.rideDate,
    this.message,
    this.declineReason,
    this.decidedAt,
  });

  RideRequest copyWith({RideRequestStatus? status}) {
    return RideRequest(
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
      status: status ?? this.status,
      declineReason: declineReason,
      decidedAt: decidedAt,
    );
  }
}
