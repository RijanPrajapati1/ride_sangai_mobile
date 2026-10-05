import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<NotificationFeed> getNotifications({bool unreadOnly = false, String? cursor, int? limit}) async {
    final page = await _dataSource.getNotifications(unreadOnly: unreadOnly, cursor: cursor, limit: limit);
    return page.toEntity();
  }

  @override
  Future<int> getUnreadCount() => _dataSource.getUnreadCount();

  @override
  Future<int> markAsRead(String id) => _dataSource.markAsRead(id);

  @override
  Future<int> markAllAsRead() => _dataSource.markAllAsRead();

  @override
  Future<void> deleteNotification(String id) => _dataSource.deleteNotification(id);
}
