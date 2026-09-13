class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String text;
  final DateTime sentAt;
  final bool isMe;

  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.text,
    required this.sentAt,
    required this.isMe,
  });
}
