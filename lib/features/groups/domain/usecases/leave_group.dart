import '../repositories/group_repository.dart';

class LeaveGroup {
  final GroupRepository _repository;

  const LeaveGroup(this._repository);

  Future<void> call(String groupId) => _repository.leaveGroup(groupId);
}
