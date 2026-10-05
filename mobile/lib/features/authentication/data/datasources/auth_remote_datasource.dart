import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../dto/auth_user_dto.dart';

/// Calls the `/auth` endpoints. Only knows about HTTP and JSON; storing the
/// tokens is the repository's job.
class AuthRemoteDataSource {
  final ApiClient _api;

  AuthRemoteDataSource(this._api);

  Future<AuthSessionDto> login({required String email, required String password}) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email.trim(), 'password': password},
    );
    return AuthSessionDto.fromJson(json);
  }

  Future<AuthSessionDto> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
    return AuthSessionDto.fromJson(json);
  }

  Future<AuthUserDto> me() async {
    final json = await _api.get<Map<String, dynamic>>(ApiEndpoints.me);
    return AuthUserDto.fromJson(json);
  }

  /// Always succeeds (202) whether or not the email has an account.
  Future<void> sendPasswordReset(String email) =>
      _api.post<dynamic>(ApiEndpoints.forgotPassword, data: {'email': email.trim()});

  /// Ends this session on the server (the refresh token stops working).
  Future<void> logout() => _api.post<dynamic>(ApiEndpoints.logout);
}
