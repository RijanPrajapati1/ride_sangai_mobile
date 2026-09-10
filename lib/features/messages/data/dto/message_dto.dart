import '../../domain/entities/message.dart';

class MessageDto {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isMe;

  MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isMe,
  });

  Message toEntity() => Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        sentAt: sentAt,
        isMe: isMe,
      );
}
