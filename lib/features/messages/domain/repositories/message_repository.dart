import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class MessageRepository {
  Future<List<Conversation>> getConversations();
  Future<List<Message>> getMessages(String conversationId);
  Future<Message> sendMessage({required String conversationId, required String text});
  Future<Conversation> getOrCreateConversationWith({
    required String userId,
    required String userName,
    required String userAvatarUrl,
  });
}
