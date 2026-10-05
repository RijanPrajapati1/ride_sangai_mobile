import '../entities/comment.dart';
import '../entities/community_post.dart';
import '../entities/like_state.dart';

abstract class CommunityRepository {
  /// The community feed, newest first. [authorId] limits it to one rider.
  Future<List<CommunityPost>> getPosts({String? authorId, int? limit});
  Future<CommunityPost> getPostById(String id);
  Future<CommunityPost> createPost({required String text, String? imageUrl});

  /// Only the fields passed are changed; pass `removeImage: true` to drop the image.
  Future<CommunityPost> updatePost(String id, {String? text, String? imageUrl, bool removeImage = false});

  /// Deletes a post (its author or an admin).
  Future<void> deletePost(String postId);

  Future<LikeState> likePost(String postId);
  Future<LikeState> unlikePost(String postId);

  /// Oldest first.
  Future<List<Comment>> getComments(String postId);
  Future<Comment> addComment({required String postId, required String text});
  Future<void> deleteComment(String commentId);
  Future<LikeState> likeComment(String commentId);
  Future<LikeState> unlikeComment(String commentId);

  /// Admin-only: every post, newest first (`GET /admin/posts`).
  Future<List<CommunityPost>> getAllPostsForAdmin({int? limit});

  /// Admin-only: removes a post and its comments (`DELETE /admin/posts/:id`).
  Future<void> adminDeletePost(String postId);
}
