import '../entities/comment.dart';
import '../repositories/community_repository.dart';

class CommentOnPost {
  final CommunityRepository _repository;

  const CommentOnPost(this._repository);

  Future<Comment> call({required String postId, required String text}) {
    return _repository.addComment(postId: postId, text: text);
  }
}
