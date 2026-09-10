import '../../domain/entities/comment.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_local_datasource.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityLocalDataSource _dataSource;

  CommunityRepositoryImpl(this._dataSource);

  @override
  Future<List<CommunityPost>> getPosts() async {
    final dtos = await _dataSource.getPosts();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<CommunityPost> getPostById(String id) async {
    final dto = await _dataSource.getPostById(id);
    return dto.toEntity();
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    final dtos = await _dataSource.getComments(postId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Comment> addComment({required String postId, required String text}) async {
    final dto = await _dataSource.addComment(postId: postId, text: text);
    return dto.toEntity();
  }

  @override
  Future<void> likePost(String postId) => _dataSource.likePost(postId);

  @override
  Future<void> unlikePost(String postId) => _dataSource.unlikePost(postId);
}
