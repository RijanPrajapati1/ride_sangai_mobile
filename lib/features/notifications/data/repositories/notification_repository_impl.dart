import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<List<NotificationItem>> getNotifications() async {
    final dtos = await _dataSource.getNotifications();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<void> markAsRead(String id) => _dataSource.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _dataSource.markAllAsRead();
}
