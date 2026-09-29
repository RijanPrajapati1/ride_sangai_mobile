import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/notification_local_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/mark_notification_as_read.dart';

final notificationLocalDataSourceProvider = Provider<NotificationLocalDataSource>((ref) {
  return NotificationLocalDataSource();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(notificationLocalDataSourceProvider));
});

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (items) => items.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});

final notificationActionsControllerProvider = Provider((ref) => NotificationActionsController(ref));

class NotificationActionsController {
  final Ref _ref;

  NotificationActionsController(this._ref);

  Future<void> markAsRead(String id) async {
    await MarkNotificationAsRead(_ref.read(notificationRepositoryProvider))(id);
    _ref.invalidate(notificationsProvider);
  }

  Future<void> markAllAsRead() async {
    await _ref.read(notificationRepositoryProvider).markAllAsRead();
    _ref.invalidate(notificationsProvider);
  }
}
