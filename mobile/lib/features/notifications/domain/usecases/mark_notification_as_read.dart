import '../repositories/notification_repository.dart';

class MarkNotificationAsRead {
  final NotificationRepository _repository;

  const MarkNotificationAsRead(this._repository);

  /// Returns the new unread count.
  Future<int> call(String id) => _repository.markAsRead(id);
}
