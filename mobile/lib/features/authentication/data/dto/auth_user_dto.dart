import '../../domain/entities/auth_user.dart';

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

  AuthUser toEntity() =>
      AuthUser(id: id, name: name, email: email, avatarUrl: avatarUrl, isAdmin: isAdmin);
}
