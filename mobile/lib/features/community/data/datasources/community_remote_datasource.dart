import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated.dart';
import '../dto/comment_dto.dart';
import '../dto/community_post_dto.dart';
import '../dto/like_state_dto.dart';

/// Calls the community endpoints (`/posts`, `/comments`) and the admin post
/// moderation endpoints (`/admin/posts`).
class CommunityRemoteDataSource {
  static const posts = '/posts';
  static String post(String id) => '/posts/$id';
  static String postLike(String id) => '/posts/$id/like';
  static String postComments(String id) => '/posts/$id/comments';
  static String comment(String id) => '/comments/$id';
  static String commentLike(String id) => '/comments/$id/like';
  static const adminPosts = '/admin/posts';
  static String adminPost(String id) => '/admin/posts/$id';

  final ApiClient _api;

  CommunityRemoteDataSource(this._api);

  Future<Paginated<CommunityPostDto>> getPosts({String? authorId, String? cursor, int? limit}) async {
    final json = await _api.get<Map<String, dynamic>>(
      posts,
      query: {'authorId': authorId, 'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, CommunityPostDto.fromJson);
  }

  Future<CommunityPostDto> getPostById(String id) async {
    final json = await _api.get<Map<String, dynamic>>(post(id));
    return CommunityPostDto.fromJson(json);
  }

  Future<CommunityPostDto> createPost({required String text, String? imageUrl}) async {
    final json = await _api.post<Map<String, dynamic>>(
      posts,
      data: {'text': text.trim(), 'imageUrl': ?imageUrl},
    );
    return CommunityPostDto.fromJson(json);
  }

  /// Sends only the given fields. `removeImage` sends `imageUrl: null`.
  Future<CommunityPostDto> updatePost(String id, {String? text, String? imageUrl, bool removeImage = false}) async {
    final json = await _api.patch<Map<String, dynamic>>(
      post(id),
      data: {
        'text': ?text?.trim(),
        if (removeImage) 'imageUrl': null else 'imageUrl': ?imageUrl,
      },
    );
    return CommunityPostDto.fromJson(json);
  }

  Future<void> deletePost(String id) => _api.delete<dynamic>(post(id));

  Future<LikeStateDto> likePost(String id) async =>
      LikeStateDto.fromJson(await _api.put<Map<String, dynamic>>(postLike(id)));

  Future<LikeStateDto> unlikePost(String id) async =>
      LikeStateDto.fromJson(await _api.delete<Map<String, dynamic>>(postLike(id)));

  Future<Paginated<CommentDto>> getComments(String postId, {String? cursor, int? limit}) async {
    final json = await _api.get<Map<String, dynamic>>(
      postComments(postId),
      query: {'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, CommentDto.fromJson);
  }

  Future<CommentDto> addComment({required String postId, required String text}) async {
    final json = await _api.post<Map<String, dynamic>>(postComments(postId), data: {'text': text.trim()});
    return CommentDto.fromJson(json);
  }

  Future<void> deleteComment(String id) => _api.delete<dynamic>(comment(id));

  Future<LikeStateDto> likeComment(String id) async =>
      LikeStateDto.fromJson(await _api.put<Map<String, dynamic>>(commentLike(id)));

  Future<LikeStateDto> unlikeComment(String id) async =>
      LikeStateDto.fromJson(await _api.delete<Map<String, dynamic>>(commentLike(id)));

  Future<Paginated<CommunityPostDto>> getAdminPosts({String? cursor, int? limit}) async {
    final json = await _api.get<Map<String, dynamic>>(adminPosts, query: {'cursor': cursor, 'limit': limit});
    return Paginated.fromJson(json, CommunityPostDto.fromJson);
  }

  Future<void> adminDeletePost(String id) => _api.delete<dynamic>(adminPost(id));
}
