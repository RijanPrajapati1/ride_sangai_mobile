import '../../../../core/enums/notification_type.dart';
import '../../domain/entities/notification_item.dart';

class NotificationDto {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime time;
  final bool isRead;
  final String? actorAvatarUrl;

  NotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    this.isRead = false,
    this.actorAvatarUrl,
  });

  NotificationDto copyWith({bool? isRead}) {
    return NotificationDto(
      id: id,
      type: type,
      title: title,
      description: description,
      time: time,
      isRead: isRead ?? this.isRead,
      actorAvatarUrl: actorAvatarUrl,
    );
  }

  NotificationItem toEntity() => NotificationItem(
        id: id,
        type: type,
        title: title,
        description: description,
        time: time,
        isRead: isRead,
        actorAvatarUrl: actorAvatarUrl,
      );
}
