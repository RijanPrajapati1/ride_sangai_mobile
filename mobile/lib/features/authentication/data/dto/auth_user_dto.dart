import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_user.dart';

/// Matches the API's `AuthUser` (`GET /auth/me`, and `user` in login/register).
class AuthUserDto {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final bool isAdmin;

  const AuthUserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.isAdmin = false,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) => AuthUserDto(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatarUrl'] as String? ?? '',
        isAdmin: json['isAdmin'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'isAdmin': isAdmin,
      };

  AuthUser toEntity() =>
      AuthUser(id: id, name: name, email: email, avatarUrl: avatarUrl, isAdmin: isAdmin);
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
