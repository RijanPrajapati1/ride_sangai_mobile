import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/community_remote_datasource.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/repositories/community_repository.dart';
import '../../domain/usecases/comment_on_post.dart';
import '../../domain/usecases/get_community_posts.dart';
import '../../domain/usecases/like_post.dart';

final communityRemoteDataSourceProvider = Provider<CommunityRemoteDataSource>((ref) {
  return CommunityRemoteDataSource(ref.watch(sessionApiClientProvider));
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(ref.watch(communityRemoteDataSourceProvider));
});

/// The first page of the community feed, newest first.
final communityPostsProvider = FutureProvider<List<CommunityPost>>((ref) {
  return GetCommunityPosts(ref.watch(communityRepositoryProvider))();
});

/// One rider's posts (for profile screens).
final userPostsProvider = FutureProvider.family<List<CommunityPost>, String>((ref, userId) {
  return ref.watch(communityRepositoryProvider).getPosts(authorId: userId);
});

final communityPostProvider = FutureProvider.family<CommunityPost, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).getPostById(postId);
});

final postCommentsProvider = FutureProvider.family<List<Comment>, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).getComments(postId);
});

final communityActionsControllerProvider = Provider((ref) => CommunityActionsController(ref));

/// Community mutations. Each one throws an `AppException` on failure (the
/// screens show its message) and refreshes the affected providers.
class CommunityActionsController {
  final Ref _ref;

  CommunityActionsController(this._ref);

  CommunityRepository get _repository => _ref.read(communityRepositoryProvider);

  void _refreshPost(String postId) {
    _ref.invalidate(communityPostsProvider);
    _ref.invalidate(userPostsProvider);
    _ref.invalidate(communityPostProvider(postId));
  }

  Future<void> toggleLike(String postId, {required bool isCurrentlyLiked}) async {
    await LikePost(_repository)(postId, isCurrentlyLiked: isCurrentlyLiked);
    _refreshPost(postId);
  }

  Future<CommunityPost> createPost({required String text, String? imageUrl}) async {
    final post = await _repository.createPost(text: text, imageUrl: imageUrl);
    _ref.invalidate(communityPostsProvider);
    _ref.invalidate(userPostsProvider);
    return post;
  }

  Future<CommunityPost> updatePost(String postId, {String? text, String? imageUrl, bool removeImage = false}) async {
    final post = await _repository.updatePost(postId, text: text, imageUrl: imageUrl, removeImage: removeImage);
    _refreshPost(postId);
    return post;
  }

  Future<void> deletePost(String postId) async {
    await _repository.deletePost(postId);
    _ref.invalidate(communityPostsProvider);
    _ref.invalidate(userPostsProvider);
  }

  Future<void> addComment({required String postId, required String text}) async {
    await CommentOnPost(_repository)(postId: postId, text: text);
    _ref.invalidate(postCommentsProvider(postId));
    _refreshPost(postId);
  }

  Future<void> deleteComment(Comment comment) async {
    await _repository.deleteComment(comment.id);
    _ref.invalidate(postCommentsProvider(comment.postId));
    _refreshPost(comment.postId);
  }

  Future<void> toggleCommentLike(Comment comment) async {
    if (comment.isLiked) {
      await _repository.unlikeComment(comment.id);
    } else {
      await _repository.likeComment(comment.id);
    }
    _ref.invalidate(postCommentsProvider(comment.postId));
  }
}
