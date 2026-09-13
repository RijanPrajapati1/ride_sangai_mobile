class Group {
  final String id;
  final String name;
  final String description;
  final String? coverImageUrl;
  final int memberCount;
  final bool isJoined;
  final String organizerId;
  final String organizerName;
  final DateTime createdAt;

  const Group({
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

  Group copyWith({int? memberCount, bool? isJoined}) {
    return Group(
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
}
