class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String text;
  final DateTime time;
  final int likeCount;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.text,
    required this.time,
    this.likeCount = 0,
  });
}
