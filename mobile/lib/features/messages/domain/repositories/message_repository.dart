import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class MessageRepository {
  Future<List<Conversation>> getConversations();
  Future<Conversation> getConversation(String conversationId);

  /// Unread messages across all conversations.
  Future<int> getUnreadCount();

  /// The latest messages, oldest first. Loading them marks the chat read.
  Future<List<Message>> getMessages(String conversationId);
  Future<Message> sendMessage({required String conversationId, required String text});
  Future<void> markRead(String conversationId);

  /// Returns the existing chat with [userId], or starts one.
  /// [userName] and [userAvatarUrl] are kept for callers; the server fills them in.
  Future<Conversation> getOrCreateConversationWith({
    required String userId,
    required String userName,
    required String userAvatarUrl,
  });
}
