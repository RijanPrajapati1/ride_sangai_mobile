import '../../domain/entities/group.dart';

class GroupDto {
  final String id;
  final String name;
  final String description;
  final String? coverImageUrl;
  final int memberCount;
  final bool isJoined;
  final String organizerId;
  final String organizerName;
  final DateTime createdAt;

  GroupDto({
    required this.id,
    required this.name,
    required this.description,
    this.coverImageUrl,
    required this.memberCount,
    required this.isJoined,
    required this.organizerId,
    required this.organizerName,
    required this.createdAt,
  });

  GroupDto copyWith({int? memberCount, bool? isJoined}) {
    return GroupDto(
      id: id,
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
      memberCount: memberCount ?? this.memberCount,
      isJoined: isJoined ?? this.isJoined,
      organizerId: organizerId,
      organizerName: organizerName,
      createdAt: createdAt,
    );
  }

  Group toEntity() => Group(
        id: id,
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
        memberCount: memberCount,
        isJoined: isJoined,
        organizerId: organizerId,
        organizerName: organizerName,
        createdAt: createdAt,
      );
}
