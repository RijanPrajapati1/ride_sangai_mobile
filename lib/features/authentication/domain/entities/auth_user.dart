/// Minimal identity returned by the auth service. Full profile data lives
/// in the profile feature and is looked up separately by [id].
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });
}
