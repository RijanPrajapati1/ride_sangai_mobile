import '../../../../core/enums/notification_type.dart';

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime time;
  final bool isRead;
  final String? actorAvatarUrl;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    this.isRead = false,
    this.actorAvatarUrl,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      description: description,
      time: time,
      isRead: isRead ?? this.isRead,
      actorAvatarUrl: actorAvatarUrl,
    );
  }
}
