import '../entities/group.dart';
import '../repositories/group_repository.dart';

class JoinGroup {
  final GroupRepository _repository;

  const JoinGroup(this._repository);

  Future<Group> call(String groupId) => _repository.joinGroup(groupId);
}
