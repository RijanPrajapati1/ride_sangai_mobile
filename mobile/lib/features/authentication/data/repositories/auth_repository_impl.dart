import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../dto/auth_user_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  AuthRepositoryImpl(this._remote, this._storage);

  /// Restores the session on app start. Asks the server who we are, so a
  /// session revoked elsewhere is noticed. If the server can't be reached,
  /// falls back to the last known user so the app still opens offline.
  @override
  Future<AuthUser?> getCurrentSession() async {
    if (await _storage.readTokens() == null) return null;
    try {
      final user = await _remote.me();
      await _storage.saveUser(user.toJson());
      return user.toEntity();
    } on AuthException {
      await _storage.clear();
      return null;
    } on AppException {
      final cached = await _storage.readUser();
      return cached == null ? null : AuthUserDto.fromJson(cached).toEntity();
    }
  }

  @override
  Future<AuthUser> login({required String email, required String password}) async {
    final session = await _remote.login(email: email, password: password);
    return _save(session);
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final session = await _remote.register(name: name, email: email, password: password);
    return _save(session);
  }

  @override
  Future<void> sendPasswordReset(String email) => _remote.sendPasswordReset(email);

  /// Signs out on the server when possible, and always forgets the tokens
  /// locally, even when offline.
  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } on AppException {
      // Best effort: the session still expires on the server by itself.
    } finally {
      await _storage.clear();
    }
  }

  Future<AuthUser> _save(AuthSessionDto session) async {
    await _storage.saveTokens(session.tokens);
    await _storage.saveUser(session.user.toJson());
    return session.user.toEntity();
  }
}
