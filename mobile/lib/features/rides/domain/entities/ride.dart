import '../../../../core/enums/ride_enums.dart';

/// The signed-in rider's own join request on a ride (`myRequest` in the API).
class MyRideRequest {
  final String id;
  final RideRequestStatus status;

  /// Set when the organizer declined with a reason.
  final String? declineReason;
  final DateTime requestedAt;

  const MyRideRequest({
    required this.id,
    required this.status,
    required this.requestedAt,
    this.declineReason,
  });
}

class Ride {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String meetingPoint;
  final RideType rideType;
  final RideDifficulty difficulty;
  final double distanceKm;
  final int durationMinutes;
  final String organizerId;
  final String organizerName;
  final String organizerAvatarUrl;

  /// '' when the ride has no cover image.
  final String imageUrl;

  /// Includes the organizer.
  final int participantCount;
  final int maxParticipants;
  final List<String> requirements;
  final List<String> participantAvatars;
  final RideJoinStatus joinStatus;

  /// The viewer's own request, if they asked to join.
  final MyRideRequest? myRequest;

  const Ride({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.meetingPoint,
    required this.rideType,
    required this.difficulty,
    required this.distanceKm,
    required this.durationMinutes,
    required this.organizerId,
    required this.organizerName,
    required this.organizerAvatarUrl,
    required this.imageUrl,
    required this.participantCount,
    required this.maxParticipants,
    this.requirements = const [],
    this.participantAvatars = const [],
    this.joinStatus = RideJoinStatus.none,
    this.myRequest,
  });

  bool get isFull => participantCount >= maxParticipants;

  bool get isOrganizer => joinStatus == RideJoinStatus.organizer;

  bool get hasStarted => !date.isAfter(DateTime.now());

  Ride copyWith({
    int? participantCount,
    List<String>? participantAvatars,
    RideJoinStatus? joinStatus,
  }) {
    return Ride(
      id: id,
      title: title,
      description: description,
      date: date,
      meetingPoint: meetingPoint,
      rideType: rideType,
      difficulty: difficulty,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      organizerId: organizerId,
      organizerName: organizerName,
      organizerAvatarUrl: organizerAvatarUrl,
      imageUrl: imageUrl,
      participantCount: participantCount ?? this.participantCount,
      maxParticipants: maxParticipants,
      requirements: requirements,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      joinStatus: joinStatus ?? this.joinStatus,
      myRequest: myRequest,
    );
  }
}
