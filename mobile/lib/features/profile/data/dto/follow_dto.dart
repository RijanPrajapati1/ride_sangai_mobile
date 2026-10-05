import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/follow_connection.dart';

/// `{ isFollowing, followersCount }` returned by follow / unfollow.
class FollowStateDto {
  final bool isFollowing;
  final int followersCount;

  const FollowStateDto({required this.isFollowing, required this.followersCount});

  factory FollowStateDto.fromJson(Map<String, dynamic> json) => FollowStateDto(
        isFollowing: json['isFollowing'] as bool,
        followersCount: json['followersCount'] as int,
      );
}

/// One row of a followers / following list.
class FollowEdgeDto {
  final String id;
  final String name;
  final String avatarUrl;
  final String location;
  final bool isFollowing;
  final DateTime followedAt;

  const FollowEdgeDto({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.location,
    required this.isFollowing,
    required this.followedAt,
  });

  factory FollowEdgeDto.fromJson(Map<String, dynamic> json) => FollowEdgeDto(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String? ?? '',
        location: json['location'] as String? ?? '',
        isFollowing: json['isFollowing'] as bool? ?? false,
        followedAt: parseDate(json['followedAt']),
      );

  FollowConnection toEntity() => FollowConnection(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        location: location,
        isFollowing: isFollowing,
        followedAt: followedAt,
      );
}
