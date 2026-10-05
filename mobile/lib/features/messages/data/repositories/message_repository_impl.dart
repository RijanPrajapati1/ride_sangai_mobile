import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_datasource.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _dataSource;

  MessageRepositoryImpl(this._dataSource);

  @override
  Future<List<Conversation>> getConversations() async {
    final page = await _dataSource.getConversations();
    return page.items.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Conversation> getConversation(String conversationId) async {
    final dto = await _dataSource.getConversation(conversationId);
    return dto.toEntity();
  }

  @override
  Future<int> getUnreadCount() => _dataSource.getUnreadCount();

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final page = await _dataSource.getMessages(conversationId);
    return page.items.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Message> sendMessage({required String conversationId, required String text}) async {
    final dto = await _dataSource.sendMessage(conversationId: conversationId, text: text.trim());
    return dto.toEntity();
  }

  @override
  Future<void> markRead(String conversationId) => _dataSource.markRead(conversationId);

  @override
  Future<Conversation> getOrCreateConversationWith({
    required String userId,
    required String userName,
    required String userAvatarUrl,
  }) async {
    // The server knows the rider's name and avatar; only the id is sent.
    final dto = await _dataSource.openConversation(userId);
    return dto.toEntity();
  }
}
