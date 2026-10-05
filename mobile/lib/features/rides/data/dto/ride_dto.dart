import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/ride.dart';

/// Matches the API's `MyRideRequest` (`myRequest` on a ride).
class MyRideRequestDto {
  final String id;
  final RideRequestStatus status;
  final String? declineReason;
  final DateTime requestedAt;

  const MyRideRequestDto({
    required this.id,
    required this.status,
    required this.requestedAt,
    this.declineReason,
  });

  factory MyRideRequestDto.fromJson(Map<String, dynamic> json) => MyRideRequestDto(
        id: json['id'] as String,
        status: enumByName(RideRequestStatus.values, json['status'], RideRequestStatus.pending),
        declineReason: json['declineReason'] as String?,
        requestedAt: parseDate(json['requestedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name,
        'declineReason': declineReason,
        'requestedAt': toApiDate(requestedAt),
      };

  MyRideRequest toEntity() =>
      MyRideRequest(id: id, status: status, declineReason: declineReason, requestedAt: requestedAt);
}

/// Matches the API's `Ride` (`GET /rides/:id` and every ride list).
class RideDto {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String meetingPoint;
  final RideType rideType;
  final DashboardCategory category;
  final RideDifficulty difficulty;
  final double distanceKm;
  final int durationMinutes;
  final String organizerId;
  final String organizerName;
  final String organizerAvatarUrl;
  final String imageUrl;
  final int participantCount;
  final int maxParticipants;
  final bool isFull;
  final List<String> requirements;
  final List<String> participantAvatars;
  final RideJoinStatus joinStatus;
  final MyRideRequestDto? myRequest;
  final DateTime createdAt;

  const RideDto({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.meetingPoint,
    required this.rideType,
    required this.category,
    required this.difficulty,
    required this.distanceKm,
    required this.durationMinutes,
    required this.organizerId,
    required this.organizerName,
    required this.organizerAvatarUrl,
    required this.imageUrl,
    required this.participantCount,
    required this.maxParticipants,
    required this.isFull,
    required this.requirements,
    required this.participantAvatars,
    required this.joinStatus,
    required this.createdAt,
    this.myRequest,
  });

  factory RideDto.fromJson(Map<String, dynamic> json) {
    final rideType = enumByName(RideType.values, json['rideType'], RideType.road);
    return RideDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      date: parseDate(json['date']),
      meetingPoint: json['meetingPoint'] as String? ?? '',
      rideType: rideType,
      category: enumByName(DashboardCategory.values, json['category'], rideType.category),
      difficulty: enumByName(RideDifficulty.values, json['difficulty'], RideDifficulty.moderate),
      distanceKm: toDouble(json['distanceKm']),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      organizerId: json['organizerId'] as String,
      organizerName: json['organizerName'] as String? ?? '',
      organizerAvatarUrl: json['organizerAvatarUrl'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      participantCount: (json['participantCount'] as num).toInt(),
      maxParticipants: (json['maxParticipants'] as num).toInt(),
      isFull: json['isFull'] as bool? ?? false,
      requirements: stringList(json['requirements']),
      participantAvatars: stringList(json['participantAvatars']),
      joinStatus: enumByName(RideJoinStatus.values, json['joinStatus'], RideJoinStatus.none),
      myRequest: json['myRequest'] == null
          ? null
          : MyRideRequestDto.fromJson(json['myRequest'] as Map<String, dynamic>),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': toApiDate(date),
        'meetingPoint': meetingPoint,
        'rideType': rideType.name,
        'category': category.name,
        'difficulty': difficulty.name,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'organizerAvatarUrl': organizerAvatarUrl,
        'imageUrl': imageUrl,
        'participantCount': participantCount,
        'maxParticipants': maxParticipants,
        'isFull': isFull,
        'requirements': requirements,
        'participantAvatars': participantAvatars,
        'joinStatus': joinStatus.name,
        'myRequest': myRequest?.toJson(),
        'createdAt': toApiDate(createdAt),
      };

  Ride toEntity() => Ride(
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
        participantCount: participantCount,
        maxParticipants: maxParticipants,
        requirements: requirements,
        participantAvatars: participantAvatars,
        joinStatus: joinStatus,
        myRequest: myRequest?.toEntity(),
      );
}

/// Body of `POST /rides` and `PATCH /rides/:id`. Null fields are left out, so
/// the same class serves a full create and a partial update.
class RideInputDto {
  final String? title;
  final String? description;
  final DateTime? date;
  final String? meetingPoint;
  final RideType? rideType;
  final RideDifficulty? difficulty;
  final double? distanceKm;
  final int? durationMinutes;
  final int? maxParticipants;
  final List<String>? requirements;
  final String? imageUrl;

  const RideInputDto({
    this.title,
    this.description,
    this.date,
    this.meetingPoint,
    this.rideType,
    this.difficulty,
    this.distanceKm,
    this.durationMinutes,
    this.maxParticipants,
    this.requirements,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (date != null) 'date': toApiDate(date!),
        if (meetingPoint != null) 'meetingPoint': meetingPoint,
        if (rideType != null) 'rideType': rideType!.name,
        if (difficulty != null) 'difficulty': difficulty!.name,
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (maxParticipants != null) 'maxParticipants': maxParticipants,
        if (requirements != null) 'requirements': requirements,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}
