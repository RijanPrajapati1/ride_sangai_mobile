import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/conversation.dart';

/// Matches the API's `Conversation` (see `GET /conversations`), as seen by the
/// signed-in rider: `userId`/`userName` are the other person.
class ConversationDto {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String? lastMessageSenderId;
  final int unreadCount;

  const ConversationDto({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) => ConversationDto(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userAvatarUrl: json['userAvatarUrl'] as String? ?? '',
        lastMessage: json['lastMessage'] as String? ?? '',
        lastMessageTime: parseDate(json['lastMessageTime']),
        lastMessageSenderId: json['lastMessageSenderId'] as String?,
        unreadCount: json['unreadCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'lastMessage': lastMessage,
        'lastMessageTime': toApiDate(lastMessageTime),
        'lastMessageSenderId': lastMessageSenderId,
        'unreadCount': unreadCount,
      };

  Conversation toEntity() => Conversation(
        id: id,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        lastMessageSenderId: lastMessageSenderId,
        unreadCount: unreadCount,
      );
}
