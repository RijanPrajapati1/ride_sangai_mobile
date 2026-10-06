/// Base exception used across data/domain layers so the presentation layer
/// can render a consistent error state regardless of the failure source.
///
/// [code] is the server's stable error code (for example `RIDE_FULL`) when
/// the failure came from the API, so callers can branch on it.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested item was not found.', String? code])
      : super(code: code);
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// Wrong credentials, or a request that needs a signed-in user.
class AuthException extends AppException {
  const AuthException([super.message = 'Invalid email or password.', String? code])
      : super(code: code);
}

/// The session can't be used any more (logged out elsewhere, refresh token
/// expired or reused). The user has to sign in again.
class SessionExpiredException extends AuthException {
  const SessionExpiredException([super.message = 'Your session has ended. Please sign in again.', super.code]);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'You do not have permission to do that.', String? code])
      : super(code: code);
}

/// The request clashes with the current state (email taken, ride full, …).
class ConflictException extends AppException {
  const ConflictException(super.message, {super.code});
}

class RateLimitException extends AppException {
  const RateLimitException([super.message = 'Too many requests. Please wait a moment and try again.', String? code])
      : super(code: code);
}

/// No connection, DNS failure or timeout: the server was never reached.
class NetworkException extends AppException {
  const NetworkException([super.message = 'No connection. Check your internet and try again.']);
}

/// The server failed (5xx) or answered with something unexpected.
class ServerException extends AppException {
  const ServerException([super.message = 'Something went wrong on our side. Please try again.', String? code])
      : super(code: code);
}
