import '../../domain/entities/group_message.dart';

class GroupMessageDto {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final DateTime sentAt;
  final bool isMe;

  GroupMessageDto({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.text,
    required this.sentAt,
    required this.isMe,
  });

  GroupMessage toEntity() => GroupMessage(
        id: id,
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        text: text,
        sentAt: sentAt,
        isMe: isMe,
      );
}
