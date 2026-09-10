import '../repositories/notification_repository.dart';

class MarkNotificationAsRead {
  final NotificationRepository _repository;

  const MarkNotificationAsRead(this._repository);

  Future<void> call(String id) => _repository.markAsRead(id);
}
