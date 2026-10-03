import '../entities/community_post.dart';
import '../repositories/community_repository.dart';

class GetCommunityPosts {
  final CommunityRepository _repository;

  const GetCommunityPosts(this._repository);

  Future<List<CommunityPost>> call() => _repository.getPosts();
}
