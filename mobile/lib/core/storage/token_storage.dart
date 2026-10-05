import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The access/refresh token pair returned by login, register and refresh.
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        accessTokenExpiresAt: DateTime.parse(json['accessTokenExpiresAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
      };

  /// True when the access token is expired or about to expire, so it's worth
  /// refreshing before sending a request instead of waiting for a 401.
  bool get isAccessTokenExpiring =>
      DateTime.now().isAfter(accessTokenExpiresAt.subtract(const Duration(seconds: 30)));
}

/// Keeps the tokens and the signed-in user in the platform's secure storage
/// (Keychain on iOS, Keystore-encrypted storage on Android), never in plain
/// SharedPreferences. Reads are cached in memory after the first one.
class TokenStorage {
  static const _tokensKey = 'auth_tokens';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _storage;
  AuthTokens? _cached;
  bool _loaded = false;

  TokenStorage(this._storage);

  Future<AuthTokens?> readTokens() async {
    if (_loaded) return _cached;
    final raw = await _storage.read(key: _tokensKey);
    _cached = raw == null ? null : _decode(raw, AuthTokens.fromJson);
    _loaded = true;
    return _cached;
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    _cached = tokens;
    _loaded = true;
    await _storage.write(key: _tokensKey, value: jsonEncode(tokens.toJson()));
  }

  /// The last signed-in user as JSON, so the app can open offline.
  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    return raw == null ? null : _decode(raw, (json) => json);
  }

  Future<void> saveUser(Map<String, dynamic> userJson) =>
      _storage.write(key: _userKey, value: jsonEncode(userJson));

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _tokensKey);
    await _storage.delete(key: _userKey);
  }

  /// Corrupt or outdated entries are treated as "signed out".
  T? _decode<T>(String raw, T Function(Map<String, dynamic>) fromJson) {
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
