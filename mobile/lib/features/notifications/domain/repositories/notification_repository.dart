import '../entities/notification_item.dart';

abstract class NotificationRepository {
  /// Newest first, with the total unread count.
  Future<NotificationFeed> getNotifications({bool unreadOnly = false, String? cursor, int? limit});

  Future<int> getUnreadCount();

  /// Returns the new unread count.
  Future<int> markAsRead(String id);

  /// Returns how many notifications were updated.
  Future<int> markAllAsRead();

  Future<void> deleteNotification(String id);
}
