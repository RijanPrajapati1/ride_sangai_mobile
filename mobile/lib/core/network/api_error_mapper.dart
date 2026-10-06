import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Turns a failed request into an [AppException] the UI can show.
///
/// Every API error uses the same envelope:
/// `{ "error": { "code": "RIDE_FULL", "message": "This ride is full." }, "requestId": "…" }`
/// `message` is written for end users, so it's passed through as-is.
class ApiErrorMapper {
  ApiErrorMapper._();

  /// Codes that mean the session is gone for good and the user must sign in.
  static const sessionEndedCodes = {
    'SESSION_REVOKED',
    'TOKEN_INVALID',
    'REFRESH_TOKEN_EXPIRED',
    'REFRESH_TOKEN_INVALID',
    'REFRESH_TOKEN_REUSED',
  };

  static AppException map(Object error) {
    if (error is AppException) return error;
    if (error is! DioException) return const ServerException();

    // An interceptor may have already decided what went wrong.
    if (error.error is AppException) return error.error as AppException;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException('The server is taking too long to respond. Please try again.');
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badCertificate:
        return const NetworkException('Secure connection failed. Please try again later.');
      case DioExceptionType.cancel:
        return const AppException('Request cancelled.', code: 'CANCELLED');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final response = error.response;
    if (response == null) return const NetworkException();

    final body = response.data;
    final envelope = body is Map<String, dynamic> ? body['error'] : null;
    final code = envelope is Map<String, dynamic> ? envelope['code'] as String? : null;
    final message = envelope is Map<String, dynamic> ? envelope['message'] as String? : null;
    final status = response.statusCode ?? 0;

    switch (status) {
      case 400:
      case 422:
        return ValidationException(_withFieldDetails(message, envelope), code: code);
      case 401:
        if (sessionEndedCodes.contains(code)) return SessionExpiredException(message ?? 'Your session has ended. Please sign in again.', code);
        return AuthException(message ?? 'Please sign in to continue.', code);
      case 403:
        return ForbiddenException(message ?? 'You do not have permission to do that.', code);
      case 404:
        return NotFoundException(message ?? 'The requested item was not found.', code);
      case 409:
        return ConflictException(message ?? 'That conflicts with the current data.', code: code);
      case 413:
        return ValidationException(message ?? 'That file is too large.', code: code);
      case 429:
        return RateLimitException(message ?? 'Too many requests. Please wait a moment and try again.', code);
      default:
        if (status >= 500) return ServerException(message ?? 'Something went wrong on our side. Please try again.', code);
        return AppException(message ?? 'Something went wrong. Please try again.', code: code);
    }
  }

  /// Validation errors carry `details: [{ field, message }]`; show the first.
  static String _withFieldDetails(String? message, Object? envelope) {
    final details = envelope is Map<String, dynamic> ? envelope['details'] : null;
    if (details is List && details.isNotEmpty && details.first is Map) {
      final first = details.first as Map;
      final field = first['field'];
      final reason = first['message'];
      if (field is String && reason is String) return '$field $reason';
    }
    return message ?? 'Please check the details and try again.';
  }
}
