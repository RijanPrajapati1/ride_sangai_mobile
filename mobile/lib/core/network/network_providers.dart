import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/token_storage.dart';
import 'api_client.dart';
import 'dio_factory.dart';

/// Tokens live in the Keychain (iOS) / Keystore-backed storage (Android).
/// `first_unlock_this_device`: readable after the first unlock following a
/// reboot, and never copied to another device through backups.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

/// Fires when the server says the session is over (revoked, expired, signed
/// out elsewhere). The auth controller listens and sends the user to login.
/// Kept separate from the auth controller to avoid a provider cycle
/// (auth controller → repository → API client → interceptor → auth controller).
class SessionEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get sessionEnded => _controller.stream;

  void notifySessionEnded() => _controller.add(null);

  void dispose() => _controller.close();
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final dioProvider = Provider<Dio>((ref) {
  final events = ref.watch(sessionEventsProvider);
  final dio = DioFactory.create(
    tokenStorage: ref.watch(tokenStorageProvider),
    onSessionEnded: events.notifySessionEnded,
  );
  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
