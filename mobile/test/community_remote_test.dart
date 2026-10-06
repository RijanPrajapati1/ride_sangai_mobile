import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sangai/core/errors/app_exception.dart';
import 'package:ride_sangai/core/network/api_client.dart';
import 'package:ride_sangai/features/community/data/datasources/community_remote_datasource.dart';
import 'package:ride_sangai/features/community/data/repositories/community_repository_impl.dart';

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

Map<String, dynamic> postJson(String id, {String? imageUrl, bool isMine = false}) => {
      'id': id,
      'userId': 'u1',
      'userName': 'Aarav',
      'userAvatarUrl': '',
      'time': '2026-10-01T10:00:00.000Z',
      'text': 'Great ride',
      'imageUrl': imageUrl,
      'likeCount': 3,
      'commentCount': 1,
      'isLiked': true,
      'isMine': isMine,
    };

Map<String, dynamic> commentJson(String id) => {
      'id': id,
      'postId': 'p1',
      'userId': 'u2',
      'userName': 'Sita',
      'userAvatarUrl': 'https://x/a.png',
      'text': 'Nice',
      'time': '2026-10-01T11:00:00.000Z',
      'likeCount': 0,
      'isLiked': false,
      'isMine': true,
    };

void main() {
  late _FakeAdapter adapter;
  late CommunityRepositoryImpl repository;

  void serve(({int status, Object? body}) Function(RequestOptions options) handler) {
    adapter = _FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = adapter;
    repository = CommunityRepositoryImpl(CommunityRemoteDataSource(ApiClient(dio)));
  }

  test('feed parses posts and passes authorId', () async {
    serve((_) => (status: 200, body: {'items': [postJson('p1', imageUrl: ''), postJson('p2', imageUrl: 'https://x/i.jpg')], 'nextCursor': null}));
    final posts = await repository.getPosts(authorId: 'u1');
    expect(adapter.requests.single.path, '/posts');
    expect(adapter.requests.single.queryParameters, {'authorId': 'u1'});
    expect(posts.map((p) => p.id), ['p1', 'p2']);
    expect(posts.first.imageUrl, isNull, reason: 'empty imageUrl means no image');
    expect(posts.last.imageUrl, 'https://x/i.jpg');
    expect(posts.first.isLiked, isTrue);
    expect(posts.first.time.isUtc, isFalse);
  });

  test('create sends text and only a non-null image', () async {
    serve((_) => (status: 201, body: postJson('p9', isMine: true)));
    final post = await repository.createPost(text: '  hello  ');
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.data, {'text': 'hello'});
    expect(post.isMine, isTrue);
  });

  test('update sends only changed fields and null to remove the image', () async {
    serve((_) => (status: 200, body: postJson('p1')));
    await repository.updatePost('p1', removeImage: true);
    expect(adapter.requests.single.method, 'PATCH');
    expect(adapter.requests.single.path, '/posts/p1');
    expect(adapter.requests.single.data, {'imageUrl': null});
  });

  test('like/unlike use PUT/DELETE and return the like state', () async {
    serve((o) => (status: 200, body: {'isLiked': o.method == 'PUT', 'likeCount': o.method == 'PUT' ? 4 : 3}));
    final liked = await repository.likePost('p1');
    final unliked = await repository.unlikeComment('c1');
    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), ['PUT /posts/p1/like', 'DELETE /comments/c1/like']);
    expect(liked.isLiked, isTrue);
    expect(liked.likeCount, 4);
    expect(unliked.isLiked, isFalse);
  });

  test('comments parse and deletes hit the right paths', () async {
    serve((o) => o.method == 'GET'
        ? (status: 200, body: {'items': [commentJson('c1')], 'nextCursor': null})
        : (status: 204, body: null));
    final comments = await repository.getComments('p1');
    await repository.deleteComment('c1');
    await repository.superadminDeletePost('p1');
    expect(comments.single.isMine, isTrue);
    expect(adapter.requests.map((r) => '${r.method} ${r.path}'),
        ['GET /posts/p1/comments', 'DELETE /comments/c1', 'DELETE /superadmin/posts/p1']);
  });

  test('server errors become AppException with the server message', () async {
    serve((_) => (status: 403, body: {'error': {'code': 'FORBIDDEN', 'message': 'Not your post.'}}));
    await expectLater(
      repository.deletePost('p1'),
      throwsA(isA<AppException>().having((e) => e.message, 'message', 'Not your post.')),
    );
  });
}
