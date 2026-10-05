import '../entities/like_state.dart';
import '../repositories/community_repository.dart';

class LikePost {
  final CommunityRepository _repository;

  const LikePost(this._repository);

  Future<LikeState> call(String postId, {required bool isCurrentlyLiked}) {
    return isCurrentlyLiked ? _repository.unlikePost(postId) : _repository.likePost(postId);
  }
}
