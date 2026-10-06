import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated.dart';
import '../dto/conversation_dto.dart';
import '../dto/message_dto.dart';

/// Calls the `/conversations` endpoints (direct messages).
class MessageRemoteDataSource {
  static const conversationsPath = '/conversations';
  static const unreadCountPath = '/conversations/unread-count';
  static String conversationPath(String id) => '/conversations/$id';
  static String messagesPath(String id) => '/conversations/$id/messages';
  static String readPath(String id) => '/conversations/$id/read';

  final ApiClient _api;

  MessageRemoteDataSource(this._api);

  /// Inbox, most recent first.
  Future<Paginated<ConversationDto>> getConversations({String? cursor, int limit = 50}) async {
    final json = await _api.get<Map<String, dynamic>>(
      conversationsPath,
      query: {'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, ConversationDto.fromJson);
  }

  /// Returns the existing chat with [userId], or creates one.
  Future<ConversationDto> openConversation(String userId) async {
    final json = await _api.post<Map<String, dynamic>>(conversationsPath, data: {'userId': userId});
    return ConversationDto.fromJson(json);
  }

  Future<int> getUnreadCount() async {
    final json = await _api.get<Map<String, dynamic>>(unreadCountPath);
    return json['count'] as int? ?? 0;
  }

  Future<ConversationDto> getConversation(String id) async {
    final json = await _api.get<Map<String, dynamic>>(conversationPath(id));
    return ConversationDto.fromJson(json);
  }

  /// Items are oldest → newest within the page; `nextCursor` loads older ones.
  /// Loading the latest page marks the chat read unless [markRead] is false.
  Future<Paginated<MessageDto>> getMessages(
    String conversationId, {
    String? cursor,
    int limit = 50,
    bool? markRead,
  }) async {
    final json = await _api.get<Map<String, dynamic>>(
      messagesPath(conversationId),
      query: {'cursor': cursor, 'limit': limit, 'markRead': markRead},
    );
    return Paginated.fromJson(json, MessageDto.fromJson);
  }

  Future<MessageDto> sendMessage({required String conversationId, required String text}) async {
    final json = await _api.post<Map<String, dynamic>>(messagesPath(conversationId), data: {'text': text});
    return MessageDto.fromJson(json);
  }

  Future<void> markRead(String conversationId) => _api.post<dynamic>(readPath(conversationId));
}
