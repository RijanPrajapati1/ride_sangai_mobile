import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sangai/app/router/route_names.dart';
import 'package:ride_sangai/core/enums/notification_type.dart';
import 'package:ride_sangai/core/network/api_client.dart';
import 'package:ride_sangai/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:ride_sangai/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:ride_sangai/features/notifications/domain/entities/notification_item.dart';
import 'package:ride_sangai/features/notifications/presentation/screens/notifications_screen.dart';

class _FakeAdapter implements HttpClientAdapter {
  final ({int status, Object? body}) Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final reply = handler(options);
    return ResponseBody.fromString(
      reply.body == null ? '' : jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> notificationJson(String id, String type, {String? entityType, String? entityId, String? avatar}) => {
      'id': id,
      'type': type,
      'title': 'Title',
      'description': 'Body',
      'time': '2026-10-01T10:00:00.000Z',
      'isRead': false,
      'actorId': null,
      'actorName': null,
      'actorAvatarUrl': avatar,
      'entityType': entityType,
      'entityId': entityId,
    };

NotificationItem item(NotificationType type, NotificationEntityType? entityType, String? entityId) =>
    NotificationItem(
      id: 'n',
      type: type,
      title: '',
      description: '',
      time: DateTime(2026),
      entityType: entityType,
      entityId: entityId,
    );

void main() {
  late _FakeAdapter adapter;
  late NotificationRepositoryImpl repository;

  void serve(({int status, Object? body}) Function(RequestOptions options) handler) {
    adapter = _FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = adapter;
    repository = NotificationRepositoryImpl(NotificationRemoteDataSource(ApiClient(dio)));
  }

  test('list parses items, unknown types and the unread count', () async {
    serve((_) => (
          status: 200,
          body: {
            'items': [
              notificationJson('n1', 'newRideRequest', entityType: 'ride', entityId: 'r1', avatar: ''),
              notificationJson('n2', 'somethingNew', entityType: 'unknownThing', entityId: 'x'),
            ],
            'nextCursor': 'abc',
            'unreadCount': 7,
          }
        ));
    final feed = await repository.getNotifications();
    expect(adapter.requests.single.path, '/notifications');
    expect(feed.unreadCount, 7);
    expect(feed.hasMore, isTrue);
    expect(feed.items.first.type, NotificationType.newRideRequest);
    expect(feed.items.first.entityType, NotificationEntityType.ride);
    expect(feed.items.first.actorAvatarUrl, isNull);
    expect(feed.items.last.type, NotificationType.other);
    expect(feed.items.last.entityType, isNull);
  });

  test('read, read-all, unread-count and delete', () async {
    serve((o) => switch (o.path) {
          '/notifications/n1/read' => (status: 200, body: {'count': 2}),
          '/notifications/read-all' => (status: 200, body: {'updated': 5}),
          '/notifications/unread-count' => (status: 200, body: {'count': 3}),
          _ => (status: 204, body: null),
        });
    expect(await repository.markAsRead('n1'), 2);
    expect(await repository.markAllAsRead(), 5);
    expect(await repository.getUnreadCount(), 3);
    await repository.deleteNotification('n1');
    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'POST /notifications/n1/read',
      'POST /notifications/read-all',
      'GET /notifications/unread-count',
      'DELETE /notifications/n1',
    ]);
  });

  test('tap routes follow the entity', () {
    expect(NotificationsScreen.routeFor(item(NotificationType.newRideRequest, NotificationEntityType.ride, 'r1')),
        RouteNames.rideRequestsPath('r1'));
    expect(NotificationsScreen.routeFor(item(NotificationType.rideReminder, NotificationEntityType.ride, 'r1')),
        RouteNames.rideDetailsPath('r1'));
    expect(NotificationsScreen.routeFor(item(NotificationType.comment, NotificationEntityType.post, 'p1')),
        RouteNames.communityPostPath('p1'));
    expect(NotificationsScreen.routeFor(item(NotificationType.placeReview, NotificationEntityType.place, 'pl')),
        RouteNames.placeDetailsPath('pl'));
    expect(NotificationsScreen.routeFor(item(NotificationType.newFollower, NotificationEntityType.user, 'u1')),
        RouteNames.userProfilePath('u1'));
    expect(NotificationsScreen.routeFor(item(NotificationType.newMessage, NotificationEntityType.conversation, 'c1')),
        RouteNames.conversationPath('c1'));
    expect(NotificationsScreen.routeFor(item(NotificationType.other, null, null)), isNull);
  });
}
