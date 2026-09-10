import '../../../../core/constants/app_constants.dart';
import '../../../../core/dummy/dummy_people.dart';
import '../../../../core/enums/notification_type.dart';
import '../dto/notification_dto.dart';

class NotificationLocalDataSource {
  NotificationLocalDataSource() {
    _notifications = _seedNotifications();
  }

  late final List<NotificationDto> _notifications;

  Future<List<NotificationDto>> getNotifications() async {
    await Future.delayed(AppConstants.dataSourceDelay);
    return List.of(_notifications)..sort((a, b) => b.time.compareTo(a.time));
  }

  Future<void> markAsRead(String id) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) _notifications[index] = _notifications[index].copyWith(isRead: true);
  }

  Future<void> markAllAsRead() async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  List<NotificationDto> _seedNotifications() {
    final now = DateTime.now();
    DateTime t(int minutesAgo) => now.subtract(Duration(minutes: minutesAgo));

    return [
      NotificationDto(
        id: 'n_001',
        type: NotificationType.requestApproved,
        title: 'Request approved',
        description: '${DummyPeople.suresh.name} approved your request to join Nagarkot Weekend Climb.',
        time: t(25),
        actorAvatarUrl: DummyPeople.suresh.avatarUrl,
      ),
      NotificationDto(
        id: 'n_002',
        type: NotificationType.newMessage,
        title: 'New message',
        description: '${DummyPeople.aarav.name} sent you a message about Saturday\'s ride.',
        time: t(60),
        actorAvatarUrl: DummyPeople.aarav.avatarUrl,
      ),
      NotificationDto(
        id: 'n_003',
        type: NotificationType.rideReminder,
        title: 'Ride starting soon',
        description: 'Budhanilkantha Foothill Ride starts in 2 hours. Don\'t forget your helmet!',
        time: t(140),
      ),
      NotificationDto(
        id: 'n_004',
        type: NotificationType.newFollower,
        title: 'New follower',
        description: '${DummyPeople.roshani.name} started following you.',
        time: t(320),
        isRead: true,
        actorAvatarUrl: DummyPeople.roshani.avatarUrl,
      ),
      NotificationDto(
        id: 'n_005',
        type: NotificationType.like,
        title: 'New like',
        description: '${DummyPeople.kabita.name} liked your post about the Godavari climb.',
        time: t(480),
        isRead: true,
        actorAvatarUrl: DummyPeople.kabita.avatarUrl,
      ),
      NotificationDto(
        id: 'n_006',
        type: NotificationType.comment,
        title: 'New comment',
        description: '${DummyPeople.bibek.name} commented on your ride photo.',
        time: t(600),
        isRead: true,
        actorAvatarUrl: DummyPeople.bibek.avatarUrl,
      ),
      NotificationDto(
        id: 'n_007',
        type: NotificationType.rideUpdated,
        title: 'Ride updated',
        description: 'The meeting point for Shivapuri Forest Trail has changed.',
        time: t(1400),
        isRead: true,
      ),
      NotificationDto(
        id: 'n_008',
        type: NotificationType.requestDeclined,
        title: 'Request declined',
        description: 'Your request to join Godavari Hills Challenge was declined — it\'s full.',
        time: t(2100),
        isRead: true,
      ),
    ];
  }
}
