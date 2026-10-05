import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sangai/core/errors/app_exception.dart';
import 'package:ride_sangai/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:ride_sangai/features/messages/data/dto/conversation_dto.dart';
import 'package:ride_sangai/features/messages/data/dto/message_dto.dart';
import 'package:ride_sangai/features/messages/data/repositories/message_repository_impl.dart';
import 'package:ride_sangai/features/messages/presentation/providers/message_providers.dart';

import 'explore_fakes.dart' show FakeAdapter, apiError, fakeApiClient, page;

Map<String, dynamic> conversationJson({String id = 'c1', int unread = 2, String? lastSender = 'u2'}) => {
      'id': id,
      'userId': 'u2',
      'userName': 'Aarav Poudel',
      'userAvatarUrl': 'https://i.pravatar.cc/150?img=13',
      'lastMessage': 'See you at Ratna Park at 5:30!',
      'lastMessageTime': '2026-10-05T06:18:54.420Z',
      'lastMessageSenderId': lastSender,
      'unreadCount': unread,
    };

Map<String, dynamic> messageJson({String id = 'm1', bool isMe = false, String text = 'Hi'}) => {
      'id': id,
      'conversationId': 'c1',
      'senderId': isMe ? 'me' : 'u2',
      'text': text,
      'sentAt': '2026-10-05T06:00:00.000Z',
      'isMe': isMe,
    };

void main() {
  group('DTOs', () {
    test('ConversationDto parses and round-trips the API shape', () {
      final json = conversationJson();
      final dto = ConversationDto.fromJson(json);
      final entity = dto.toEntity();
      expect(entity.userName, 'Aarav Poudel');
      expect(entity.unreadCount, 2);
      expect(entity.lastMessageSenderId, 'u2');
      expect(entity.lastMessageTime.isUtc, isFalse, reason: 'shown in local time');
      expect(entity.lastMessageTime.toUtc(), DateTime.parse('2026-10-05T06:18:54.420Z'));
      final back = dto.toJson();
      expect(back.keys.toSet(), json.keys.toSet());
      expect(DateTime.parse(back['lastMessageTime'] as String), DateTime.parse(json['lastMessageTime'] as String));
    });

    test('a new chat has no last sender', () {
      final dto = ConversationDto.fromJson({...conversationJson(lastSender: null), 'lastMessage': 'Say hello 👋'});
      expect(dto.lastMessageSenderId, isNull);
      expect(dto.lastMessage, 'Say hello 👋');
    });

    test('MessageDto parses and round-trips the API shape', () {
      final json = messageJson(isMe: true);
      final dto = MessageDto.fromJson(json);
      expect(dto.toEntity().isMe, isTrue);
      expect(dto.toJson().keys.toSet(), json.keys.toSet());
    });
  });

  group('MessageRemoteDataSource + repository', () {
    late FakeAdapter adapter;
    late MessageRemoteDataSource source;
    late MessageRepositoryImpl repository;

    Future<void> serve(({int status, Object? body}) Function(dynamic options) handler) async {
      adapter = FakeAdapter((options) => handler(options));
      source = MessageRemoteDataSource(await fakeApiClient(adapter));
      repository = MessageRepositoryImpl(source);
    }

    test('inbox, single conversation and unread count', () async {
      await serve((options) => switch (options.path as String) {
            '/conversations' => (status: 200, body: page([conversationJson(), conversationJson(id: 'c2', unread: 0)], 'n')),
            '/conversations/unread-count' => (status: 200, body: {'count': 5}),
            '/conversations/c1' => (status: 200, body: conversationJson()),
            _ => (status: 404, body: apiError('CONVERSATION_NOT_FOUND', 'This conversation could not be found.')),
          });
      final inbox = await repository.getConversations();
      expect(inbox.map((c) => c.id), ['c1', 'c2']);
      expect(adapter.last.queryParameters, {'limit': 50});

      final pageWithCursor = await source.getConversations(cursor: 'n', limit: 10);
      expect(pageWithCursor.nextCursor, 'n');
      expect(adapter.last.queryParameters, {'cursor': 'n', 'limit': 10});

      expect(await repository.getUnreadCount(), 5);
      expect((await repository.getConversation('c1')).userName, 'Aarav Poudel');

      await expectLater(
        repository.getConversation('nope'),
        throwsA(isA<NotFoundException>().having((e) => e.message, 'message', 'This conversation could not be found.')),
      );
    });

    test('messages: history, send (trimmed) and mark read', () async {
      await serve((options) => switch ((options.method as String, options.path as String)) {
            ('GET', '/conversations/c1/messages') =>
              (status: 200, body: page([messageJson(id: 'm1'), messageJson(id: 'm2', isMe: true)])),
            ('POST', '/conversations/c1/messages') => (status: 201, body: messageJson(id: 'm3', isMe: true, text: 'Hello')),
            ('POST', '/conversations/c1/read') => (status: 204, body: null),
            _ => (status: 404, body: apiError('NOT_FOUND', 'Nope.')),
          });
      final messages = await repository.getMessages('c1');
      expect(messages.map((m) => m.id), ['m1', 'm2'], reason: 'oldest first');
      expect(adapter.last.queryParameters.containsKey('markRead'), isFalse, reason: 'server default marks it read');

      await source.getMessages('c1', markRead: false);
      expect(adapter.last.queryParameters['markRead'], false);

      final sent = await repository.sendMessage(conversationId: 'c1', text: '  Hello ');
      expect(sent.isMe, isTrue);
      expect(adapter.last.data, {'text': 'Hello'});

      await repository.markRead('c1');
      expect(adapter.last.method, 'POST');
      expect(adapter.last.path, '/conversations/c1/read');
    });

    test('opening a chat sends only the rider id', () async {
      await serve((_) => (status: 201, body: conversationJson(id: 'new', unread: 0, lastSender: null)));
      final conversation = await repository.getOrCreateConversationWith(
        userId: 'u2',
        userName: 'ignored',
        userAvatarUrl: 'ignored',
      );
      expect(conversation.id, 'new');
      expect(conversation.userName, 'Aarav Poudel', reason: 'the server fills in the name');
      expect(adapter.last.path, '/conversations');
      expect(adapter.last.data, {'userId': 'u2'});
    });

    test('CANNOT_MESSAGE_SELF surfaces the server message', () async {
      await serve((_) => (status: 400, body: apiError('CANNOT_MESSAGE_SELF', "You can't message yourself.")));
      await expectLater(
        repository.getOrCreateConversationWith(userId: 'me', userName: '', userAvatarUrl: ''),
        throwsA(isA<AppException>().having((e) => e.message, 'message', "You can't message yourself.")),
      );
    });
  });

  test('providers: unread badge comes from /conversations/unread-count; sending refreshes it', () async {
    var unread = 3;
    final adapter = FakeAdapter((options) => switch ((options.method, options.path)) {
          ('GET', '/conversations/unread-count') => (status: 200, body: {'count': unread}),
          ('POST', '/conversations/c1/messages') => (status: 201, body: messageJson(isMe: true)),
          _ => (status: 404, body: apiError('NOT_FOUND', 'Nope.')),
        });
    final api = await fakeApiClient(adapter);
    final container = ProviderContainer(overrides: [
      messageRemoteDataSourceProvider.overrideWithValue(MessageRemoteDataSource(api)),
    ]);
    addTearDown(container.dispose);
    final listener = container.listen(totalUnreadMessagesProvider, (_, _) {});

    expect(listener.read(), 0, reason: 'loading');
    expect(await container.read(unreadMessagesCountProvider.future), 3);
    expect(listener.read(), 3);

    unread = 0;
    await container.read(messageActionsControllerProvider).sendMessage(conversationId: 'c1', text: 'Hi');
    expect(await container.read(unreadMessagesCountProvider.future), 0);
  });
}
