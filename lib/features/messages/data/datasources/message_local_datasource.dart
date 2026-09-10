import '../../../../core/constants/app_constants.dart';
import '../../../../core/dummy/dummy_people.dart';
import '../dto/conversation_dto.dart';
import '../dto/message_dto.dart';

class MessageLocalDataSource {
  MessageLocalDataSource() {
    _conversations = _seedConversations();
    _messages = _seedMessages();
  }

  late final List<ConversationDto> _conversations;
  late final Map<String, List<MessageDto>> _messages;
  int _messageSeq = 100;

  Future<List<ConversationDto>> getConversations() async {
    await Future.delayed(AppConstants.dataSourceDelay);
    return List.of(_conversations)
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  }

  Future<List<MessageDto>> getMessages(String conversationId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    return List.of(_messages[conversationId] ?? const []);
  }

  Future<MessageDto> sendMessage({required String conversationId, required String text}) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final message = MessageDto(
      id: 'm_${_messageSeq++}',
      conversationId: conversationId,
      senderId: DummyPeople.me.id,
      text: text,
      sentAt: DateTime.now(),
      isMe: true,
    );
    _messages.putIfAbsent(conversationId, () => []).add(message);

    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: text,
        lastMessageTime: message.sentAt,
        unreadCount: 0,
      );
    }
    return message;
  }

  List<ConversationDto> _seedConversations() {
    final now = DateTime.now();
    return [
      ConversationDto(
        id: 'c_001',
        userId: DummyPeople.aarav.id,
        userName: DummyPeople.aarav.name,
        userAvatarUrl: DummyPeople.aarav.avatarUrl,
        lastMessage: 'Great, see you at Ratna Park at 5:30 sharp!',
        lastMessageTime: now.subtract(const Duration(minutes: 12)),
        unreadCount: 2,
      ),
      ConversationDto(
        id: 'c_002',
        userId: DummyPeople.suresh.id,
        userName: DummyPeople.suresh.name,
        userAvatarUrl: DummyPeople.suresh.avatarUrl,
        lastMessage: 'Bring a spare tube, the descent is rough this season.',
        lastMessageTime: now.subtract(const Duration(hours: 3)),
        unreadCount: 0,
      ),
      ConversationDto(
        id: 'c_003',
        userId: DummyPeople.priya.id,
        userName: DummyPeople.priya.name,
        userAvatarUrl: DummyPeople.priya.avatarUrl,
        lastMessage: 'Loved the photos from Sunday\'s ride!',
        lastMessageTime: now.subtract(const Duration(hours: 26)),
        unreadCount: 0,
      ),
      ConversationDto(
        id: 'c_004',
        userId: DummyPeople.anita.id,
        userName: DummyPeople.anita.name,
        userAvatarUrl: DummyPeople.anita.avatarUrl,
        lastMessage: 'Are you joining the Shivapuri trail next weekend?',
        lastMessageTime: now.subtract(const Duration(days: 2)),
        unreadCount: 1,
      ),
      ConversationDto(
        id: 'c_005',
        userId: DummyPeople.kabita.id,
        userName: DummyPeople.kabita.name,
        userAvatarUrl: DummyPeople.kabita.avatarUrl,
        lastMessage: 'Thanks for leading the spin yesterday 🙌',
        lastMessageTime: now.subtract(const Duration(days: 4)),
        unreadCount: 0,
      ),
    ];
  }

  Map<String, List<MessageDto>> _seedMessages() {
    final now = DateTime.now();
    DateTime t(int minutesAgo) => now.subtract(Duration(minutes: minutesAgo));

    return {
      'c_001': [
        MessageDto(
          id: 'm_001',
          conversationId: 'c_001',
          senderId: DummyPeople.aarav.id,
          text: 'Hey! Are you in for the Kathmandu Sunrise Ride this Saturday?',
          sentAt: t(90),
          isMe: false,
        ),
        MessageDto(
          id: 'm_002',
          conversationId: 'c_001',
          senderId: DummyPeople.me.id,
          text: 'Yes, count me in. What time should I be there?',
          sentAt: t(75),
          isMe: true,
        ),
        MessageDto(
          id: 'm_003',
          conversationId: 'c_001',
          senderId: DummyPeople.aarav.id,
          text: 'We\'re meeting at Ratna Park at 5:30am, before the traffic picks up.',
          sentAt: t(60),
          isMe: false,
        ),
        MessageDto(
          id: 'm_004',
          conversationId: 'c_001',
          senderId: DummyPeople.aarav.id,
          text: 'Bring lights just in case, and a light jacket, it\'s chilly that early.',
          sentAt: t(58),
          isMe: false,
        ),
        MessageDto(
          id: 'm_005',
          conversationId: 'c_001',
          senderId: DummyPeople.me.id,
          text: 'Perfect, I\'ll be there. Thanks for organizing!',
          sentAt: t(40),
          isMe: true,
        ),
        MessageDto(
          id: 'm_006',
          conversationId: 'c_001',
          senderId: DummyPeople.aarav.id,
          text: 'Great, see you at Ratna Park at 5:30 sharp!',
          sentAt: t(12),
          isMe: false,
        ),
      ],
      'c_002': [
        MessageDto(
          id: 'm_010',
          conversationId: 'c_002',
          senderId: DummyPeople.suresh.id,
          text: 'The Nagarkot descent has some loose gravel patches this week.',
          sentAt: t(200),
          isMe: false,
        ),
        MessageDto(
          id: 'm_011',
          conversationId: 'c_002',
          senderId: DummyPeople.me.id,
          text: 'Good to know, I\'ll take it easy on the way down.',
          sentAt: t(190),
          isMe: true,
        ),
        MessageDto(
          id: 'm_012',
          conversationId: 'c_002',
          senderId: DummyPeople.suresh.id,
          text: 'Bring a spare tube, the descent is rough this season.',
          sentAt: t(180),
          isMe: false,
        ),
      ],
      'c_003': [
        MessageDto(
          id: 'm_020',
          conversationId: 'c_003',
          senderId: DummyPeople.priya.id,
          text: 'Loved the photos from Sunday\'s ride!',
          sentAt: t(1560),
          isMe: false,
        ),
      ],
      'c_004': [
        MessageDto(
          id: 'm_030',
          conversationId: 'c_004',
          senderId: DummyPeople.anita.id,
          text: 'Are you joining the Shivapuri trail next weekend?',
          sentAt: t(2880),
          isMe: false,
        ),
      ],
      'c_005': [
        MessageDto(
          id: 'm_040',
          conversationId: 'c_005',
          senderId: DummyPeople.kabita.id,
          text: 'Thanks for leading the spin yesterday 🙌',
          sentAt: t(5760),
          isMe: false,
        ),
      ],
    };
  }
}
