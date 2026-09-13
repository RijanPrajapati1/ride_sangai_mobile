import '../entities/group_message.dart';
import '../repositories/group_repository.dart';

class SendGroupMessage {
  final GroupRepository _repository;

  const SendGroupMessage(this._repository);

  Future<GroupMessage> call({required String groupId, required String text}) {
    return _repository.sendGroupMessage(groupId: groupId, text: text);
  }
}
