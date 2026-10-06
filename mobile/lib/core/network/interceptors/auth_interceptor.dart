import 'package:dio/dio.dart';

import '../../errors/app_exception.dart';
import '../../storage/token_storage.dart';
import '../api_endpoints.dart';
import '../api_error_mapper.dart';

/// Adds `Authorization: Bearer <accessToken>` to every request and keeps the
/// access token fresh.
///
/// * Before a request: if the access token is about to expire, refresh first.
/// * After a `401 TOKEN_EXPIRED`: refresh, then retry the request once.
/// * If the session is gone (revoked, refresh token expired or reused):
///   clear the stored tokens and call [onSessionEnded] so the app signs out.
///
/// Refresh tokens are single-use on the server, and replaying one revokes the
/// whole session. So only one refresh ever runs at a time: requests that need
/// a new token while a refresh is in flight wait for that same refresh.
class AuthInterceptor extends Interceptor {
  static const _retriedKey = 'auth_retried';

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _storage;
  final void Function() _onSessionEnded;

  Future<AuthTokens>? _refreshing;

  /// [dio] is the client this interceptor is attached to (used for retries).
  /// [refreshDio] must NOT have this interceptor, so refreshing can't loop.
  AuthInterceptor({
    required this._dio,
    required this._refreshDio,
    required this._storage,
    required this._onSessionEnded,
  });

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isPublic(options)) return handler.next(options);

    var tokens = await _storage.readTokens();
    if (tokens == null) return handler.next(options);

    if (tokens.isAccessTokenExpiring) {
      try {
        tokens = await _refreshTokens();
      } on SessionExpiredException catch (e) {
        return handler.reject(DioException(requestOptions: options, error: e));
      } on AppException {
        // Offline or the server hiccuped: send the old token and let the
        // request fail (or succeed) on its own.
      }
    }

    options.headers['Authorization'] = 'Bearer ${tokens!.accessToken}';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || _isPublic(options)) return handler.next(err);

    final code = _errorCode(err.response);
    if (ApiErrorMapper.sessionEndedCodes.contains(code)) {
      await _endSession();
      return handler.next(err);
    }
    if (code != 'TOKEN_EXPIRED' || options.extra[_retriedKey] == true) return handler.next(err);

    try {
      final tokens = await _freshTokensAfterFailure(options);
      options
        ..extra[_retriedKey] = true
        ..headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } on AppException catch (e) {
      handler.next(DioException(requestOptions: options, response: err.response, error: e));
    }
  }

  /// Another request may have refreshed already while this one was in
  /// flight. Use those tokens instead of spending the refresh token again.
  Future<AuthTokens> _freshTokensAfterFailure(RequestOptions failed) async {
    final current = await _storage.readTokens();
    final sentHeader = failed.headers['Authorization'];
    if (current != null && sentHeader != 'Bearer ${current.accessToken}') return current;
    return _refreshTokens();
  }

  Future<AuthTokens> _refreshTokens() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<AuthTokens> _doRefresh() async {
    final current = await _storage.readTokens();
    if (current == null) throw const SessionExpiredException();

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': current.refreshToken},
      );
      final body = response.data!;
      final tokens = AuthTokens.fromJson(body);
      await _storage.saveTokens(tokens);
      if (body['user'] is Map<String, dynamic>) await _storage.saveUser(body['user'] as Map<String, dynamic>);
      return tokens;
    } catch (error) {
      final mapped = ApiErrorMapper.map(error);
      if (mapped is AuthException) {
        await _endSession();
        throw SessionExpiredException(mapped.message, mapped.code);
      }
      throw mapped;
    }
  }

  Future<void> _endSession() async {
    await _storage.clear();
    _onSessionEnded();
  }

  bool _isPublic(RequestOptions options) => ApiEndpoints.publicAuthPaths.contains(options.path);

  String? _errorCode(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      return (data['error'] as Map<String, dynamic>)['code'] as String?;
    }
    return null;
  }
}
