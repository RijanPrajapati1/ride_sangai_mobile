import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yatrix/core/enums/dashboard_category.dart';
import 'package:yatrix/core/enums/ride_enums.dart';
import 'package:yatrix/core/errors/app_exception.dart';
import 'package:yatrix/core/network/api_client.dart';
import 'package:yatrix/features/profile/data/datasources/user_remote_datasource.dart';
import 'package:yatrix/features/profile/data/repositories/user_repository_impl.dart';
import 'package:yatrix/features/profile/domain/entities/user_preferences.dart';

/// Answers requests from a handler instead of the network, and records them.
class FakeAdapter implements HttpClientAdapter {
  final ({int status, Object? body}) Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  FakeAdapter(this.handler);

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

Map<String, dynamic> profileJson(String id, {String? email, bool isMe = false}) => {
      'id': id,
      'name': 'Rider $id',
      'email': email,
      'avatarUrl': '',
      'bio': '',
      'location': 'Kathmandu',
      'experienceLevel': 'advanced',
      'preferredRideType': 'hillClimb',
      'cyclingInterests': ['Gravel'],
      'totalRides': 4,
      'completedRides': 2,
      'followersCount': 10,
      'followingCount': 3,
      'isFollowing': true,
      'isMe': isMe,
      'isPrivate': false,
      'statsHidden': true,
    };

const prefsJson = {
  'pushRideReminders': true,
  'pushMessages': false,
  'pushCommunityActivity': true,
  'darkModeEnabled': false,
  'publicProfile': true,
  'showRidingStats': false,
};

void main() {
  late FakeAdapter adapter;
  late UserRepositoryImpl repository;

  void serve(({int status, Object? body}) Function(RequestOptions options) handler) {
    adapter = FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = adapter;
    repository = UserRepositoryImpl(UserRemoteDataSource(ApiClient(dio)));
  }

  test('parses a profile, mapping a hidden email to an empty string', () async {
    serve((o) => (status: 200, body: profileJson('u2')));
    final profile = await repository.getProfile('u2');

    expect(adapter.requests.single.path, '/users/u2');
    expect(profile.email, '');
    expect(profile.experienceLevel, ExperienceLevel.advanced);
    expect(profile.preferredRideType, RideType.hillClimb);
    expect(profile.cyclingInterests, ['Gravel']);
    expect(profile.isFollowing, isTrue);
    expect(profile.statsHidden, isTrue);
  });

  test('updateProfile sends only the editable fields to PATCH /me', () async {
    serve((o) => (status: 200, body: profileJson('me', email: 'me@example.com', isMe: true)));
    final me = await repository.getMyProfile();
    await repository.updateProfile(me.copyWith(name: '  New Name ', bio: 'Hi'));

    final patch = adapter.requests.last;
    expect(patch.method, 'PATCH');
    expect(patch.path, '/me');
    expect(patch.data, {
      'name': 'New Name',
      'avatarUrl': '',
      'bio': 'Hi',
      'location': 'Kathmandu',
      'experienceLevel': 'advanced',
      'preferredRideType': 'hillClimb',
      'cyclingInterests': ['Gravel'],
    });
  });

  test('patchPreferences sends only the changed toggle', () async {
    serve((o) => (status: 200, body: prefsJson));
    final prefs = await repository.patchPreferences(publicProfile: false);

    expect(adapter.requests.single.method, 'PATCH');
    expect(adapter.requests.single.path, '/me/preferences');
    expect(adapter.requests.single.data, {'publicProfile': false});
    expect(prefs.pushMessages, isFalse);
  });

  test('updatePreferences replaces every toggle with PUT', () async {
    serve((o) => (status: 200, body: prefsJson));
    await repository.updatePreferences(const UserPreferences(darkModeEnabled: true));

    expect(adapter.requests.single.method, 'PUT');
    expect((adapter.requests.single.data as Map)['darkModeEnabled'], isTrue);
    expect((adapter.requests.single.data as Map).length, 6);
  });

  test('follow and unfollow use PUT / DELETE on the follow resource', () async {
    serve((o) => (status: 200, body: {'isFollowing': o.method == 'PUT', 'followersCount': 1}));
    await repository.followUser('u2');
    await repository.unfollowUser('u2');

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), ['PUT /users/u2/follow', 'DELETE /users/u2/follow']);
  });

  test('recommended riders are scoped to the dashboard category', () async {
    serve((o) => (status: 200, body: {'items': [profileJson('u3')]}));
    final riders = await repository.getRecommendedRiders(category: DashboardCategory.hiking);

    expect(adapter.requests.single.path, '/users/recommended');
    expect(adapter.requests.single.queryParameters, {'category': 'hiking'});
    expect(riders.single.id, 'u3');
  });

  test('followers are paginated', () async {
    serve((o) => (
          status: 200,
          body: {
            'items': [
              {
                'id': 'u4',
                'name': 'Follower',
                'avatarUrl': '',
                'location': '',
                'isFollowing': false,
                'followedAt': '2026-01-02T03:04:05.000Z',
              }
            ],
            'nextCursor': 'next',
          },
        ));
    final page = await repository.getFollowers('u2', cursor: 'abc');

    expect(adapter.requests.single.path, '/users/u2/followers');
    expect(adapter.requests.single.queryParameters, {'cursor': 'abc'});
    expect(page.items.single.followedAt.toUtc(), DateTime.utc(2026, 1, 2, 3, 4, 5));
    expect(page.hasMore, isTrue);
  });

  test('getAllUsers loads every superadmin page', () async {
    serve((o) => o.queryParameters['cursor'] == null
        ? (status: 200, body: {'items': [profileJson('a')], 'nextCursor': 'c2'})
        : (status: 200, body: {'items': [profileJson('b')], 'nextCursor': null}));
    final users = await repository.getAllUsers();

    expect(users.map((u) => u.id), ['a', 'b']);
    expect(adapter.requests.every((r) => r.path == '/superadmin/users'), isTrue);
  });

  test('server errors surface as AppException with the server message', () async {
    serve((o) => (
          status: 400,
          body: {
            'error': {'code': 'INVALID_PASSWORD', 'message': 'That password is not right.'},
          },
        ));

    expect(
      () => repository.deleteAccount('wrong'),
      throwsA(isA<AppException>().having((e) => e.message, 'message', 'That password is not right.')),
    );
  });
}
