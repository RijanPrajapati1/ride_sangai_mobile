/// A post's or comment's like state after a like/unlike.
class LikeState {
  final bool isLiked;
  final int likeCount;

  const LikeState({required this.isLiked, required this.likeCount});
}
