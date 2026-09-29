import '../entities/message.dart';
import '../repositories/message_repository.dart';

class SendMessage {
  final MessageRepository _repository;

  const SendMessage(this._repository);

  Future<Message> call({required String conversationId, required String text}) {
    return _repository.sendMessage(conversationId: conversationId, text: text);
  }
}
