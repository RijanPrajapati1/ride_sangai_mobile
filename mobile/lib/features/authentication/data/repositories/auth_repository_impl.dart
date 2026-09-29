import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<AuthUser?> getCurrentSession() async {
    final dto = await _dataSource.getCurrentSession();
    return dto?.toEntity();
  }

  @override
  Future<AuthUser> login({required String email, required String password}) async {
    final dto = await _dataSource.login(email: email, password: password);
    return dto.toEntity();
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final dto = await _dataSource.register(name: name, email: email, password: password);
    return dto.toEntity();
  }

  @override
  Future<void> sendPasswordReset(String email) => _dataSource.sendPasswordReset(email);

  @override
  Future<void> logout() => _dataSource.logout();
}
