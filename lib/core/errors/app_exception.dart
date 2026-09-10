/// Base exception used across data/domain layers so the presentation layer
/// can render a consistent error state regardless of the failure source.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested item was not found.']);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Invalid email or password.']);
}
