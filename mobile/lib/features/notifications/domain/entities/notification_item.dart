import '../../../../core/enums/notification_type.dart';

/// What a notification points at, so tapping it can open the right screen.
enum NotificationEntityType { ride, rideRequest, post, comment, user, conversation, group, place }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime time;
  final bool isRead;
  final String? actorId;
  final String? actorName;
  final String? actorAvatarUrl;
  final NotificationEntityType? entityType;
  final String? entityId;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    this.isRead = false,
    this.actorId,
    this.actorName,
    this.actorAvatarUrl,
    this.entityType,
    this.entityId,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      description: description,
      time: time,
      isRead: isRead ?? this.isRead,
      actorId: actorId,
      actorName: actorName,
      actorAvatarUrl: actorAvatarUrl,
      entityType: entityType,
      entityId: entityId,
    );
  }
}

/// One page of notifications plus the total unread count (for the bell badge).
class NotificationFeed {
  final List<NotificationItem> items;
  final int unreadCount;
  final String? nextCursor;

  const NotificationFeed({required this.items, required this.unreadCount, this.nextCursor});

  bool get hasMore => nextCursor != null;
}
