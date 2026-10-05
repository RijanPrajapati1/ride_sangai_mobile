import '../../domain/entities/comment.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/like_state.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_remote_datasource.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  /// Comments are shown in one list under the post; this is the API maximum.
  static const _commentPageSize = 100;

  final CommunityRemoteDataSource _dataSource;

  CommunityRepositoryImpl(this._dataSource);

  @override
  Future<List<CommunityPost>> getPosts({String? authorId, int? limit}) async {
    final page = await _dataSource.getPosts(authorId: authorId, limit: limit);
    return page.items.map((d) => d.toEntity()).toList();
  }

  @override
  Future<CommunityPost> getPostById(String id) async => (await _dataSource.getPostById(id)).toEntity();

  @override
  Future<CommunityPost> createPost({required String text, String? imageUrl}) async =>
      (await _dataSource.createPost(text: text, imageUrl: imageUrl)).toEntity();

  @override
  Future<CommunityPost> updatePost(String id, {String? text, String? imageUrl, bool removeImage = false}) async =>
      (await _dataSource.updatePost(id, text: text, imageUrl: imageUrl, removeImage: removeImage)).toEntity();

  @override
  Future<void> deletePost(String postId) => _dataSource.deletePost(postId);

  @override
  Future<LikeState> likePost(String postId) async => (await _dataSource.likePost(postId)).toEntity();

  @override
  Future<LikeState> unlikePost(String postId) async => (await _dataSource.unlikePost(postId)).toEntity();

  @override
  Future<List<Comment>> getComments(String postId) async {
    final page = await _dataSource.getComments(postId, limit: _commentPageSize);
    return page.items.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Comment> addComment({required String postId, required String text}) async =>
      (await _dataSource.addComment(postId: postId, text: text)).toEntity();

  @override
  Future<void> deleteComment(String commentId) => _dataSource.deleteComment(commentId);

  @override
  Future<LikeState> likeComment(String commentId) async => (await _dataSource.likeComment(commentId)).toEntity();

  @override
  Future<LikeState> unlikeComment(String commentId) async =>
      (await _dataSource.unlikeComment(commentId)).toEntity();

  @override
  Future<List<CommunityPost>> getAllPostsForSuperadmin({int? limit}) async {
    final page = await _dataSource.getSuperadminPosts(limit: limit);
    return page.items.map((d) => d.toEntity()).toList();
  }

  @override
  Future<void> superadminDeletePost(String postId) => _dataSource.superadminDeletePost(postId);
}
