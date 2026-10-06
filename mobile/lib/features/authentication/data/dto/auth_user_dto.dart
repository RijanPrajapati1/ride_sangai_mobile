import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_user.dart';

/// Matches the API's `AuthUser` (`GET /auth/me`, and `user` in login/register).
class AuthUserDto {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  /// `user` or `superadmin`.
  final String role;
  final bool isSuperadmin;

  const AuthUserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.role = 'user',
    this.isSuperadmin = false,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String? ?? 'user';
    return AuthUserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      role: role,
      isSuperadmin: json['isSuperadmin'] as bool? ?? role == 'superadmin',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'role': role,
        'isSuperadmin': isSuperadmin,
      };

  AuthUser toEntity() => AuthUser(
        id: id,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        role: UserRole.fromName(role),
        isSuperadmin: isSuperadmin,
      );
}

/// What login, register and refresh return: the user plus a token pair.
class AuthSessionDto {
  final AuthUserDto user;
  final AuthTokens tokens;

  const AuthSessionDto({required this.user, required this.tokens});

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) => AuthSessionDto(
        user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(json),
      );
}
