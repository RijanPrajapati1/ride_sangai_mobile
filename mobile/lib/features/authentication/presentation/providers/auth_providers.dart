import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider), ref.watch(tokenStorageProvider));
});

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  late final StreamSubscription<void> _sessionEnded;

  AuthController(this._repository, SessionEvents sessionEvents) : super(const AuthState()) {
    // The server ended the session (signed out elsewhere, token revoked):
    // drop to the login screen. The router reacts to the status change.
    _sessionEnded = sessionEvents.sessionEnded.listen((_) {
      if (state.status == AuthStatus.authenticated) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'Your session has ended. Please sign in again.',
        );
      }
    });
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    AuthUser? user;
    try {
      user = await _repository.getCurrentSession();
    } catch (_) {
      user = null;
    }
    if (!mounted) return;
    state = AuthState(
      status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      user: user,
    );
  }

  @override
  void dispose() {
    _sessionEnded.cancel();
    super.dispose();
  }

  String _message(Object error) =>
      error is AppException ? error.message : 'Something went wrong. Please try again.';

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _message(e));
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.register(name: name, email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _message(e));
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.sendPasswordReset(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _message(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref.watch(sessionEventsProvider));
});
