class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final DateTime time;
  final String text;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.time,
    required this.text,
    this.imageUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });

  CommunityPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLiked,
  }) {
    return CommunityPost(
      id: id,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      time: time,
      text: text,
      imageUrl: imageUrl,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
