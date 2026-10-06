/// API paths, relative to `AppConfig.apiBaseUrl` (which ends in `/api/v1`).
/// Full request/response details: http://localhost:4000/docs
class ApiEndpoints {
  ApiEndpoints._();

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const forgotPassword = '/auth/forgot-password';
  static const me = '/auth/me';

  /// Requests to these never carry a token and never trigger a refresh.
  static const publicAuthPaths = {login, register, refresh, forgotPassword};
}
