import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/message.dart';

/// Matches the API's `Message`. `isMe` is computed by the server for the viewer.
class MessageDto {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isMe;

  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isMe,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) => MessageDto(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String,
        senderId: json['senderId'] as String,
        text: json['text'] as String,
        sentAt: parseDate(json['sentAt']),
        isMe: json['isMe'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'sentAt': toApiDate(sentAt),
        'isMe': isMe,
      };

  Message toEntity() => Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        sentAt: sentAt,
        isMe: isMe,
      );
}
