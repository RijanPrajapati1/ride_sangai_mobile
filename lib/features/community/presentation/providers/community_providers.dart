import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/community_local_datasource.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/repositories/community_repository.dart';
import '../../domain/usecases/comment_on_post.dart';
import '../../domain/usecases/like_post.dart';

final communityLocalDataSourceProvider = Provider<CommunityLocalDataSource>((ref) {
  return CommunityLocalDataSource();
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(ref.watch(communityLocalDataSourceProvider));
});

final communityPostsProvider = FutureProvider<List<CommunityPost>>((ref) {
  return ref.watch(communityRepositoryProvider).getPosts();
});

final communityPostProvider = FutureProvider.family<CommunityPost, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).getPostById(postId);
});

final postCommentsProvider = FutureProvider.family<List<Comment>, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).getComments(postId);
});

final communityActionsControllerProvider = Provider((ref) => CommunityActionsController(ref));

class CommunityActionsController {
  final Ref _ref;

  CommunityActionsController(this._ref);

  Future<void> toggleLike(String postId, {required bool isCurrentlyLiked}) async {
    await LikePost(_ref.read(communityRepositoryProvider))(postId, isCurrentlyLiked: isCurrentlyLiked);
    _ref.invalidate(communityPostsProvider);
    _ref.invalidate(communityPostProvider(postId));
  }

  Future<void> addComment({required String postId, required String text}) async {
    await CommentOnPost(_ref.read(communityRepositoryProvider))(postId: postId, text: text);
    _ref.invalidate(postCommentsProvider(postId));
    _ref.invalidate(communityPostsProvider);
    _ref.invalidate(communityPostProvider(postId));
  }
}
