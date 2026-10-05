import '../../../../core/network/api_client.dart';
import '../dto/notification_dto.dart';

/// Calls the `/notifications` endpoints.
class NotificationRemoteDataSource {
  static const notifications = '/notifications';
  static const unreadCount = '/notifications/unread-count';
  static const readAll = '/notifications/read-all';
  static String notification(String id) => '/notifications/$id';
  static String read(String id) => '/notifications/$id/read';

  final ApiClient _api;

  NotificationRemoteDataSource(this._api);

  Future<NotificationPageDto> getNotifications({bool unreadOnly = false, String? cursor, int? limit}) async {
    final json = await _api.get<Map<String, dynamic>>(
      notifications,
      query: {'unreadOnly': unreadOnly ? true : null, 'cursor': cursor, 'limit': limit},
    );
    return NotificationPageDto.fromJson(json);
  }

  Future<int> getUnreadCount() async {
    final json = await _api.get<Map<String, dynamic>>(unreadCount);
    return json['count'] as int;
  }

  /// Idempotent. Returns the new unread count.
  Future<int> markAsRead(String id) async {
    final json = await _api.post<Map<String, dynamic>>(read(id));
    return json['count'] as int;
  }

  /// Returns how many notifications were marked read.
  Future<int> markAllAsRead() async {
    final json = await _api.post<Map<String, dynamic>>(readAll);
    return json['updated'] as int;
  }

  Future<void> deleteNotification(String id) => _api.delete<dynamic>(notification(id));
}
