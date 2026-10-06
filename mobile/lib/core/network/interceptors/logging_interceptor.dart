import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only request log: method, path, status and timing.
///
/// Bodies and headers are never printed, so passwords and tokens can't end up
/// in device logs. Only added to the client in debug builds.
class LoggingInterceptor extends Interceptor {
  static const _startKey = 'log_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, '${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final data = err.response?.data;
    final code = data is Map && data['error'] is Map ? (data['error'] as Map)['code'] : null;
    _log(err.requestOptions, status != null ? '$status ${code ?? ''}'.trim() : err.type.name);
    handler.next(err);
  }

  void _log(RequestOptions options, String outcome) {
    final started = options.extra[_startKey];
    final ms = started is DateTime ? DateTime.now().difference(started).inMilliseconds : null;
    debugPrint('[API] ${options.method} ${options.path} → $outcome${ms != null ? ' (${ms}ms)' : ''}');
  }
}
