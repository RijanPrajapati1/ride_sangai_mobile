/// Platform role. Every rider is a `user` and manages their own rides, posts,
/// places and groups; `superadmin` runs the platform (web dashboard, and the
/// in-app dashboard when they sign in on a phone).
enum UserRole {
  user,
  superadmin;

  /// Unknown values fall back to [user] so a newer server never grants
  /// extra access by accident.
  static UserRole fromName(String? name) =>
      UserRole.values.firstWhere((r) => r.name == name, orElse: () => UserRole.user);
}

/// Minimal identity returned by the auth service. Full profile data lives
/// in the profile feature and is looked up separately by [id].
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final UserRole role;
  final bool isSuperadmin;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.role = UserRole.user,
    this.isSuperadmin = false,
  });
}
