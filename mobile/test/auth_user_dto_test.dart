import 'package:flutter_test/flutter_test.dart';
import 'package:yatrix/features/authentication/data/dto/auth_user_dto.dart';
import 'package:yatrix/features/authentication/domain/entities/auth_user.dart';

void main() {
  Map<String, dynamic> userJson(Map<String, dynamic> extra) =>
      {'id': 'u1', 'name': 'Alex', 'email': 'alex@example.com', 'avatarUrl': '', ...extra};

  test('reads role and isSuperadmin from the API', () {
    final rider = AuthUserDto.fromJson(userJson({'role': 'user', 'isSuperadmin': false})).toEntity();
    expect(rider.role, UserRole.user);
    expect(rider.isSuperadmin, isFalse);

    final superadmin = AuthUserDto.fromJson(userJson({'role': 'superadmin', 'isSuperadmin': true})).toEntity();
    expect(superadmin.role, UserRole.superadmin);
    expect(superadmin.isSuperadmin, isTrue);
  });

  test('round-trips through the cached JSON', () {
    final dto = AuthUserDto.fromJson(userJson({'role': 'superadmin', 'isSuperadmin': true}));
    final restored = AuthUserDto.fromJson(dto.toJson()).toEntity();
    expect(restored.isSuperadmin, isTrue);
    expect(restored.role, UserRole.superadmin);
  });

  test('an old cached user (isAdmin, no role) is a regular rider', () {
    final user = AuthUserDto.fromJson(userJson({'isAdmin': true})).toEntity();
    expect(user.role, UserRole.user);
    expect(user.isSuperadmin, isFalse);
  });

  test('an unknown role never grants superadmin', () {
    final user = AuthUserDto.fromJson(userJson({'role': 'moderator'})).toEntity();
    expect(user.role, UserRole.user);
    expect(user.isSuperadmin, isFalse);
  });
}
