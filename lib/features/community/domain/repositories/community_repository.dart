import '../entities/comment.dart';
import '../entities/community_post.dart';

abstract class CommunityRepository {
  Future<List<CommunityPost>> getPosts();
  Future<CommunityPost> getPostById(String id);
  Future<List<Comment>> getComments(String postId);
  Future<Comment> addComment({required String postId, required String text});
  Future<void> likePost(String postId);
  Future<void> unlikePost(String postId);
}
