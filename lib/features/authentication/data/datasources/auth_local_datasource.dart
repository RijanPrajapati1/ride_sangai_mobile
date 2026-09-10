import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/dummy/dummy_people.dart';
import '../../../../core/errors/app_exception.dart';
import '../dto/auth_user_dto.dart';

/// Simulates an auth backend using SharedPreferences to persist the "logged
/// in" state between launches. A future `AuthRemoteDataSource` implementing
/// the same shape can call Firebase Auth or a REST API instead.
class AuthLocalDataSource {
  static const demoEmail = 'demo@bikersync.app';
  static const demoPassword = 'biker123';

  Future<AuthUserDto?> getCurrentSession() async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(AppConstants.authTokenKey);
    if (email == null) return null;
    return _dtoForEmail(email);
  }

  Future<AuthUserDto> login({required String email, required String password}) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    final normalized = email.trim().toLowerCase();
    if (normalized != demoEmail && password.length < 6) {
      throw const AuthException();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.authTokenKey, normalized);
    return _dtoForEmail(normalized);
  }

  Future<AuthUserDto> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    final prefs = await SharedPreferences.getInstance();
    final normalized = email.trim().toLowerCase();
    await prefs.setString(AppConstants.authTokenKey, normalized);
    return AuthUserDto(
      id: DummyPeople.me.id,
      name: name,
      email: normalized,
      avatarUrl: DummyPeople.me.avatarUrl,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(AppConstants.dataSourceDelay);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authTokenKey);
  }

  AuthUserDto _dtoForEmail(String email) {
    return AuthUserDto(
      id: DummyPeople.me.id,
      name: DummyPeople.me.name,
      email: email,
      avatarUrl: DummyPeople.me.avatarUrl,
    );
  }
}
