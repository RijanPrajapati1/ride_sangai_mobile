import '../../domain/entities/auth_user.dart';

class AuthUserDto {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  const AuthUserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  AuthUser toEntity() => AuthUser(id: id, name: name, email: email, avatarUrl: avatarUrl);
}
