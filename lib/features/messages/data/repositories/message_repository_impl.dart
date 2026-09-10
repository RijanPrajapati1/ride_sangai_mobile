import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_local_datasource.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageLocalDataSource _dataSource;

  MessageRepositoryImpl(this._dataSource);

  @override
  Future<List<Conversation>> getConversations() async {
    final dtos = await _dataSource.getConversations();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final dtos = await _dataSource.getMessages(conversationId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Message> sendMessage({required String conversationId, required String text}) async {
    final dto = await _dataSource.sendMessage(conversationId: conversationId, text: text);
    return dto.toEntity();
  }
}
