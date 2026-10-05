import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sangai/core/errors/app_exception.dart';
import 'package:ride_sangai/core/network/api_client.dart';
import 'package:ride_sangai/core/network/dio_factory.dart';
import 'package:ride_sangai/core/storage/token_storage.dart';

/// Answers requests from a handler instead of the network, and records them.
class FakeAdapter implements HttpClientAdapter {
  final ({int status, Object? body}) Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final reply = handler(options);
    return ResponseBody.fromString(
      reply.body == null ? '' : jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  int count(String path) => requests.where((r) => r.path == path).length;

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> apiError(String code, [String message = 'Nope.']) => {
      'error': {'code': code, 'message': message},
      'requestId': 'test',
    };

Map<String, dynamic> session(String access, String refresh) => {
      'user': {'id': 'u1', 'name': 'Alex', 'email': 'alex@example.com', 'avatarUrl': '', 'isAdmin': false},
      'accessToken': access,
      'refreshToken': refresh,
      'tokenType': 'Bearer',
      'expiresIn': 900,
      'accessTokenExpiresAt': DateTime.now().add(const Duration(minutes: 15)).toUtc().toIso8601String(),
      'refreshTokenExpiresAt': DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
    };

void main() {
  late TokenStorage storage;
  late int sessionEndedCalls;

  ApiClient clientWith(FakeAdapter adapter) => ApiClient(DioFactory.create(
        tokenStorage: storage,
        onSessionEnded: () => sessionEndedCalls++,
        baseUrl: 'http://test/api/v1',
        adapter: adapter,
      ));

  Future<void> signIn({String access = 'old-access', Duration expiresIn = const Duration(minutes: 15)}) =>
      storage.saveTokens(AuthTokens(
        accessToken: access,
        refreshToken: 'refresh-1',
        accessTokenExpiresAt: DateTime.now().add(expiresIn),
      ));

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = TokenStorage(const FlutterSecureStorage());
    sessionEndedCalls = 0;
  });

  test('sends the stored access token as a Bearer header', () async {
    await signIn();
    final adapter = FakeAdapter((_) => (status: 200, body: {'ok': true}));

    await clientWith(adapter).get<Map<String, dynamic>>('/rides');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer old-access');
  });

  test('never sends a token to login', () async {
    await signIn();
    final adapter = FakeAdapter((_) => (status: 200, body: session('a', 'r')));

    await clientWith(adapter).post<Map<String, dynamic>>('/auth/login', data: {'email': 'x', 'password': 'y'});

    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('on TOKEN_EXPIRED, refreshes once for concurrent requests and retries them', () async {
    await signIn();
    final adapter = FakeAdapter((options) {
      if (options.path == '/auth/refresh') return (status: 200, body: session('new-access', 'refresh-2'));
      final authorized = options.headers['Authorization'] == 'Bearer new-access';
      return authorized ? (status: 200, body: {'path': options.path}) : (status: 401, body: apiError('TOKEN_EXPIRED'));
    });
    final api = clientWith(adapter);

    final results = await Future.wait([
      api.get<Map<String, dynamic>>('/rides'),
      api.get<Map<String, dynamic>>('/posts'),
      api.get<Map<String, dynamic>>('/groups'),
    ]);

    expect(results.map((r) => r['path']), ['/rides', '/posts', '/groups']);
    expect(adapter.count('/auth/refresh'), 1, reason: 'refresh tokens are single-use on the server');
    expect((await storage.readTokens())!.refreshToken, 'refresh-2');
    expect(sessionEndedCalls, 0);
  });

  test('refreshes before the request when the access token is about to expire', () async {
    await signIn(expiresIn: const Duration(seconds: 5));
    final adapter = FakeAdapter((options) => options.path == '/auth/refresh'
        ? (status: 200, body: session('new-access', 'refresh-2'))
        : (status: 200, body: {'ok': true}));

    await clientWith(adapter).get<Map<String, dynamic>>('/rides');

    expect(adapter.requests.map((r) => r.path), ['/auth/refresh', '/rides']);
    expect(adapter.requests.last.headers['Authorization'], 'Bearer new-access');
  });

  test('a rejected refresh token signs the user out', () async {
    await signIn();
    final adapter = FakeAdapter((options) => options.path == '/auth/refresh'
        ? (status: 401, body: apiError('REFRESH_TOKEN_REUSED', 'Your session has ended. Please sign in again.'))
        : (status: 401, body: apiError('TOKEN_EXPIRED')));

    await expectLater(
      clientWith(adapter).get<Map<String, dynamic>>('/rides'),
      throwsA(isA<SessionExpiredException>().having((e) => e.code, 'code', 'REFRESH_TOKEN_REUSED')),
    );
    expect(await storage.readTokens(), isNull);
    expect(sessionEndedCalls, 1);
  });

  test('a revoked session signs the user out without trying to refresh', () async {
    await signIn();
    final adapter = FakeAdapter((_) => (status: 401, body: apiError('SESSION_REVOKED')));

    await expectLater(clientWith(adapter).get<dynamic>('/rides'), throwsA(isA<SessionExpiredException>()));
    expect(adapter.count('/auth/refresh'), 0);
    expect(await storage.readTokens(), isNull);
    expect(sessionEndedCalls, 1);
  });

  test('maps the error envelope to typed exceptions with the server message and code', () async {
    final adapter = FakeAdapter((options) => switch (options.path) {
          '/full' => (status: 409, body: apiError('RIDE_FULL', 'This ride is full.')),
          '/missing' => (status: 404, body: apiError('RIDE_NOT_FOUND', 'This ride no longer exists.')),
          '/invalid' => (
              status: 400,
              body: {
                'error': {
                  'code': 'VALIDATION_ERROR',
                  'message': 'Invalid request.',
                  'details': [
                    {'field': 'email', 'message': 'must match format "email"'},
                  ],
                },
              },
            ),
          _ => (status: 500, body: null),
        });
    final api = clientWith(adapter);

    await expectLater(
      api.get<dynamic>('/full'),
      throwsA(isA<ConflictException>()
          .having((e) => e.code, 'code', 'RIDE_FULL')
          .having((e) => e.message, 'message', 'This ride is full.')),
    );
    await expectLater(api.get<dynamic>('/missing'), throwsA(isA<NotFoundException>()));
    await expectLater(
      api.get<dynamic>('/invalid'),
      throwsA(isA<ValidationException>().having((e) => e.message, 'message', 'email must match format "email"')),
    );
    await expectLater(api.get<dynamic>('/boom'), throwsA(isA<ServerException>()));
  });

  test('turns a connection failure into a NetworkException', () async {
    final dio = DioFactory.create(
      tokenStorage: storage,
      onSessionEnded: () {},
      baseUrl: 'http://127.0.0.1:1/api/v1',
    );

    await expectLater(ApiClient(dio).get<dynamic>('/rides'), throwsA(isA<NetworkException>()));
  });
}
