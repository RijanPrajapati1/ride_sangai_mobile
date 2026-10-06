import '../../../../core/enums/notification_type.dart';
import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/notification_item.dart';

/// Matches the API's `NotificationItem` (`GET /notifications`).
class NotificationDto {
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

  const NotificationDto({
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

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    final entityType = json['entityType'];
    final avatar = json['actorAvatarUrl'] as String?;
    return NotificationDto(
      id: json['id'] as String,
      type: enumByName(NotificationType.values, json['type'], NotificationType.other),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      time: parseDate(json['time']),
      isRead: json['isRead'] as bool? ?? false,
      actorId: json['actorId'] as String?,
      actorName: json['actorName'] as String?,
      // An actor without a photo sends '' — treat it like no avatar.
      actorAvatarUrl: avatar == null || avatar.isEmpty ? null : avatar,
      entityType: entityType == null
          ? null
          : NotificationEntityType.values.where((e) => e.name == entityType).firstOrNull,
      entityId: json['entityId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'time': toApiDate(time),
        'isRead': isRead,
        'actorId': actorId,
        'actorName': actorName,
        'actorAvatarUrl': actorAvatarUrl,
        'entityType': entityType?.name,
        'entityId': entityId,
      };

  NotificationItem toEntity() => NotificationItem(
        id: id,
        type: type,
        title: title,
        description: description,
        time: time,
        isRead: isRead,
        actorId: actorId,
        actorName: actorName,
        actorAvatarUrl: actorAvatarUrl,
        entityType: entityType,
        entityId: entityId,
      );
}

/// Matches the API's `NotificationPage`: `{ items, nextCursor, unreadCount }`.
class NotificationPageDto {
  final List<NotificationDto> items;
  final String? nextCursor;
  final int unreadCount;

  const NotificationPageDto({required this.items, this.nextCursor, required this.unreadCount});

  factory NotificationPageDto.fromJson(Map<String, dynamic> json) => NotificationPageDto(
        items: (json['items'] as List)
            .map((item) => NotificationDto.fromJson(item as Map<String, dynamic>))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
        unreadCount: json['unreadCount'] as int? ?? 0,
      );

  NotificationFeed toEntity() => NotificationFeed(
        items: items.map((d) => d.toEntity()).toList(),
        unreadCount: unreadCount,
        nextCursor: nextCursor,
      );
}
