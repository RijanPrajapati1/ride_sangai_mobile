import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/message_local_datasource.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/usecases/send_message.dart';

final messageLocalDataSourceProvider = Provider<MessageLocalDataSource>((ref) {
  return MessageLocalDataSource();
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(ref.watch(messageLocalDataSourceProvider));
});

final conversationsProvider = FutureProvider<List<Conversation>>((ref) {
  return ref.watch(messageRepositoryProvider).getConversations();
});

final conversationMessagesProvider = FutureProvider.family<List<Message>, String>((ref, conversationId) {
  return ref.watch(messageRepositoryProvider).getMessages(conversationId);
});

final messageActionsControllerProvider = Provider((ref) => MessageActionsController(ref));

class MessageActionsController {
  final Ref _ref;

  MessageActionsController(this._ref);

  Future<void> sendMessage({required String conversationId, required String text}) async {
    await SendMessage(_ref.read(messageRepositoryProvider))(conversationId: conversationId, text: text);
    _ref.invalidate(conversationMessagesProvider(conversationId));
    _ref.invalidate(conversationsProvider);
  }
}
