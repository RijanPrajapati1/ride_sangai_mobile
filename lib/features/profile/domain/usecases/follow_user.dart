import '../repositories/user_repository.dart';

class FollowUser {
  final UserRepository _repository;

  const FollowUser(this._repository);

  Future<void> call(String userId, {required bool isCurrentlyFollowing}) {
    return isCurrentlyFollowing ? _repository.unfollowUser(userId) : _repository.followUser(userId);
  }
}
