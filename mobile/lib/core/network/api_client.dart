import 'package:dio/dio.dart';

import 'api_error_mapper.dart';

/// The one place features talk to the API through.
///
/// Every method returns the decoded JSON body, or throws an `AppException`
/// (never a raw `DioException`), so repositories and the UI only deal with
/// the app's own error types. Tokens, refresh and logging are handled by the
/// interceptors on the underlying [Dio].
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<T> get<T>(String path, {Map<String, dynamic>? query, CancelToken? cancelToken}) =>
      _send(() => _dio.get<T>(path, queryParameters: _clean(query), cancelToken: cancelToken));

  Future<T> post<T>(String path, {Object? data, Map<String, dynamic>? query, CancelToken? cancelToken}) =>
      _send(() => _dio.post<T>(path, data: data, queryParameters: _clean(query), cancelToken: cancelToken));

  Future<T> put<T>(String path, {Object? data, CancelToken? cancelToken}) =>
      _send(() => _dio.put<T>(path, data: data, cancelToken: cancelToken));

  Future<T> patch<T>(String path, {Object? data, CancelToken? cancelToken}) =>
      _send(() => _dio.patch<T>(path, data: data, cancelToken: cancelToken));

  Future<T> delete<T>(String path, {Object? data, CancelToken? cancelToken}) =>
      _send(() => _dio.delete<T>(path, data: data, cancelToken: cancelToken));

  /// Uploads one file as `multipart/form-data` (see `POST /uploads`).
  Future<T> upload<T>(
    String path, {
    required MultipartFile file,
    Map<String, String> fields = const {},
    ProgressCallback? onSendProgress,
  }) =>
      _send(() => _dio.post<T>(
            path,
            data: FormData.fromMap({...fields, 'file': file}),
            onSendProgress: onSendProgress,
          ));

  Future<T> _send<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } catch (error) {
      throw ApiErrorMapper.map(error);
    }
  }

  /// Drops null values so optional filters can be passed straight through.
  Map<String, dynamic>? _clean(Map<String, dynamic>? query) =>
      query == null ? null : (Map.of(query)..removeWhere((_, value) => value == null));
}
