import '../entities/conversation.dart';
import '../repositories/message_repository.dart';

class GetConversations {
  final MessageRepository _repository;

  const GetConversations(this._repository);

  Future<List<Conversation>> call() => _repository.getConversations();
}
