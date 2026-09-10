import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser?> getCurrentSession();
  Future<AuthUser> login({required String email, required String password});
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> sendPasswordReset(String email);
  Future<void> logout();
}
