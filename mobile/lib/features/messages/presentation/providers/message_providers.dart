import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/datasources/message_remote_datasource.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/usecases/get_conversations.dart';
import '../../domain/usecases/send_message.dart';

final messageRemoteDataSourceProvider = Provider<MessageRemoteDataSource>((ref) {
  return MessageRemoteDataSource(ref.watch(sessionApiClientProvider));
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(ref.watch(messageRemoteDataSourceProvider));
});

final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  return GetConversations(ref.watch(messageRepositoryProvider))();
});

/// One conversation (the chat header), straight from `GET /conversations/:id`.
final conversationProvider = FutureProvider.family<Conversation, String>((ref, conversationId) {
  return ref.watch(messageRepositoryProvider).getConversation(conversationId);
});

final conversationMessagesProvider = FutureProvider.family<List<Message>, String>((ref, conversationId) {
  return ref.watch(messageRepositoryProvider).getMessages(conversationId);
});

/// Unread messages across all chats (`GET /conversations/unread-count`).
final unreadMessagesCountProvider = FutureProvider<int>((ref) {
  return ref.watch(messageRepositoryProvider).getUnreadCount();
});

/// Badge count; 0 while loading or on error.
final totalUnreadMessagesProvider = Provider<int>((ref) {
  return ref.watch(unreadMessagesCountProvider).maybeWhen(data: (count) => count, orElse: () => 0);
});

final messageActionsControllerProvider = Provider((ref) => MessageActionsController(ref));

class MessageActionsController {
  final Ref _ref;

  MessageActionsController(this._ref);

  void _refreshInbox() {
    _ref.invalidate(conversationsProvider);
    _ref.invalidate(unreadMessagesCountProvider);
  }

  Future<void> sendMessage({required String conversationId, required String text}) async {
    await SendMessage(_ref.read(messageRepositoryProvider))(conversationId: conversationId, text: text);
    _ref.invalidate(conversationMessagesProvider(conversationId));
    _ref.invalidate(conversationProvider(conversationId));
    _refreshInbox();
  }

  /// Marks the chat read and refreshes the inbox badges.
  Future<void> markRead(String conversationId) async {
    await _ref.read(messageRepositoryProvider).markRead(conversationId);
    _refreshInbox();
  }

  /// Re-fetches the chat (there is no realtime yet; pull to refresh).
  void refreshConversation(String conversationId) {
    _ref.invalidate(conversationMessagesProvider(conversationId));
    _ref.invalidate(conversationProvider(conversationId));
    _refreshInbox();
  }

  Future<Conversation> openConversationWith({
    required String userId,
    required String userName,
    required String userAvatarUrl,
  }) async {
    final conversation = await _ref.read(messageRepositoryProvider).getOrCreateConversationWith(
          userId: userId,
          userName: userName,
          userAvatarUrl: userAvatarUrl,
        );
    _ref.invalidate(conversationsProvider);
    return conversation;
  }
}
