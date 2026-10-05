class Conversation {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;

  /// Who sent the last message; null until the first message.
  final String? lastMessageSenderId;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
  });

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    int? unreadCount,
  }) {
    return Conversation(
      id: id,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
