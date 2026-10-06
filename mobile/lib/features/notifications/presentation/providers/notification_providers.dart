import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_notification_as_read.dart';

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(ref.watch(apiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(notificationRemoteDataSourceProvider));
});

/// The latest notifications plus the total unread count.
final notificationsProvider = FutureProvider<NotificationFeed>((ref) {
  return GetNotifications(ref.watch(notificationRepositoryProvider))();
});

/// Unread count for the bell badge. Comes from the server with the list, so it
/// also counts unread notifications beyond the first page. Keeps the previous
/// value while the list reloads.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).valueOrNull?.unreadCount ?? 0;
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

  Future<void> delete(String id) async {
    try {
      await _ref.read(notificationRepositoryProvider).deleteNotification(id);
    } finally {
      // Refetch even on failure so a dismissed tile comes back.
      _ref.invalidate(notificationsProvider);
    }
  }
}
