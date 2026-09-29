import '../entities/notification_item.dart';
import '../repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository _repository;

  const GetNotifications(this._repository);

  Future<List<NotificationItem>> call() => _repository.getNotifications();
}
