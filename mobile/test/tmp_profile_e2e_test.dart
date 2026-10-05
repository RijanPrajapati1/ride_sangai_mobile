import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_sangai/core/errors/app_exception.dart';
import 'package:ride_sangai/core/network/api_client.dart';
import 'package:ride_sangai/core/network/dio_factory.dart';
import 'package:ride_sangai/core/network/upload_service.dart';
import 'package:ride_sangai/core/storage/token_storage.dart';
import 'package:ride_sangai/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:ride_sangai/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:ride_sangai/features/profile/data/datasources/user_remote_datasource.dart';
import 'package:ride_sangai/features/profile/data/repositories/user_repository_impl.dart';

Future<ApiClient> client({String? email, String? password, String? registerName}) async {
  FlutterSecureStorage.setMockInitialValues({});
  final storage = TokenStorage(const FlutterSecureStorage());
  final api = ApiClient(DioFactory.create(tokenStorage: storage, onSessionEnded: () {}, baseUrl: 'http://localhost:4000/api/v1'));
  final auth = AuthRepositoryImpl(AuthRemoteDataSource(api), storage);
  if (registerName != null) {
    await auth.register(name: registerName, email: email!, password: password!);
  } else {
    await auth.login(email: email!, password: password!);
  }
  return api;
}

void main() {
  test('profile + settings endpoints against the live server', () async {
    final api = await client(email: 'demo@bikersync.app', password: 'biker123');
    final remote = UserRemoteDataSource(api);
    final repo = UserRepositoryImpl(remote);

    // GET /me + PATCH /me (restored)
    final me = await remote.getMe();
    expect(me.isMe, isTrue);
    expect(me.email, 'demo@bikersync.app');
    print('me: ${me.id} ${me.name} followers=${me.followersCount} following=${me.followingCount}');
    final edited = await remote.updateMe({'bio': 'e2e bio', 'name': 'E2E Name'});
    expect(edited.bio, 'e2e bio');
    expect(edited.name, 'E2E Name');
    final restored = await repo.updateProfile(me.toEntity());
    expect(restored.bio, me.bio);
    expect(restored.name, me.name);
    expect(restored.avatarUrl, me.avatarUrl);
    expect(restored.cyclingInterests, me.cyclingInterests);

    // Avatar upload + set + restore
    const png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';
    final url = await UploadService(api).uploadImage(
      XFile.fromData(base64Decode(png), name: 'a.png', mimeType: 'image/png'),
      purpose: UploadPurpose.avatar,
    );
    print('uploaded avatar: $url');
    expect((await remote.updateMe({'avatarUrl': url})).avatarUrl, url);
    expect((await remote.updateMe({'avatarUrl': me.avatarUrl})).avatarUrl, me.avatarUrl);

    // Preferences: GET, PATCH, PUT (restored)
    final prefs = await remote.getPreferences();
    final patched = await repo.patchPreferences(pushMessages: !prefs.pushMessages);
    expect(patched.pushMessages, !prefs.pushMessages);
    final replaced = await remote.replacePreferences(prefs);
    expect(replaced.toJson(), prefs.toJson());

    // Search, recommended, user by id
    final search = await remote.searchUsers(query: 'a', limit: 5);
    print('search a: ${search.items.length} next=${search.nextCursor}');
    expect(search.items, isNotEmpty);
    final recommended = await remote.getRecommended(category: 'cycling', limit: 5);
    print('recommended: ${recommended.map((r) => r.name).toList()}');
    final other = search.items.firstWhere((u) => !u.isMe);
    final otherProfile = await remote.getUser(other.id);
    expect(otherProfile.id, other.id);
    expect(otherProfile.isMe, isFalse);

    // Follow / unfollow, ending in the original state
    final wasFollowing = otherProfile.isFollowing;
    if (wasFollowing) {
      final s1 = await remote.unfollowUser(other.id);
      expect(s1.isFollowing, isFalse);
      final s2 = await remote.followUser(other.id);
      expect(s2.isFollowing, isTrue);
      expect(s2.followersCount, otherProfile.followersCount);
    } else {
      final s1 = await remote.followUser(other.id);
      expect(s1.isFollowing, isTrue);
      final following = await remote.getFollowing(me.id, limit: 100);
      expect(following.items.any((e) => e.id == other.id), isTrue);
      final followers = await remote.getFollowers(other.id, limit: 100);
      expect(followers.items.any((e) => e.id == me.id), isTrue);
      final s2 = await remote.unfollowUser(other.id);
      expect(s2.isFollowing, isFalse);
      expect(s2.followersCount, otherProfile.followersCount);
    }
    final followers = await remote.getFollowers(me.id, limit: 2);
    final following = await remote.getFollowing(me.id, limit: 2);
    print('my followers page: ${followers.items.length} next=${followers.nextCursor}; '
        'following page: ${following.items.length} next=${following.nextCursor}');
    expect((await remote.getUser(other.id)).isFollowing, wasFollowing);

    // Admin endpoints are forbidden for a rider
    await expectLater(remote.getAdminUsers(), throwsA(isA<ForbiddenException>()));

    // DELETE /me on a throwaway account
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final tempApi = await client(
      registerName: 'E2E Delete $stamp',
      email: 'e2e.delete.$stamp@example.com',
      password: 'E2ePassw0rd!',
    );
    final tempRemote = UserRemoteDataSource(tempApi);
    await expectLater(tempRemote.deleteMe('wrong-password'), throwsA(isA<AppException>()));
    await tempRemote.deleteMe('E2ePassw0rd!');
    print('self-deleted throwaway account');

    // Admin: list + remove a throwaway rider
    final victimApi = await client(
      registerName: 'E2E Remove $stamp',
      email: 'e2e.remove.$stamp@example.com',
      password: 'E2ePassw0rd!',
    );
    final victim = await UserRemoteDataSource(victimApi).getMe();
    final adminApi = await client(email: 'admin@gmail.com', password: 'Test@1234');
    final adminRemote = UserRemoteDataSource(adminApi);
    final adminRepo = UserRepositoryImpl(adminRemote);
    final found = await adminRemote.getAdminUsers(query: 'e2e.remove.$stamp', role: 'user');
    expect(found.items.single.id, victim.id);
    final all = await adminRepo.getAllUsers();
    print('admin getAllUsers: ${all.length} users');
    expect(all.any((u) => u.id == victim.id), isTrue);
    expect(all.any((u) => u.email == 'demo@bikersync.app'), isTrue);
    await adminRepo.removeUser(victim.id);
    await expectLater(adminRemote.getUser(victim.id), throwsA(isA<NotFoundException>()));
    print('admin removed throwaway rider');

    // Demo account unchanged
    final after = await remote.getMe();
    expect(after.name, me.name);
    expect(after.bio, me.bio);
    expect(after.avatarUrl, me.avatarUrl);
    expect(after.followingCount, me.followingCount);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
