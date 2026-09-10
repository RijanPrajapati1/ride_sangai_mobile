import '../../../../core/enums/ride_enums.dart';

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
  final String imageUrl;
  final int participantCount;
  final int maxParticipants;
  final List<String> requirements;
  final List<String> participantAvatars;
  final RideJoinStatus joinStatus;

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
  });

  bool get isFull => participantCount >= maxParticipants;

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
    );
  }
}
