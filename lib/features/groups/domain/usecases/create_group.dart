import '../entities/group.dart';
import '../repositories/group_repository.dart';

class CreateGroup {
  final GroupRepository _repository;

  const CreateGroup(this._repository);

  Future<Group> call({required String name, required String description}) {
    return _repository.createGroup(name: name, description: description);
  }
}
