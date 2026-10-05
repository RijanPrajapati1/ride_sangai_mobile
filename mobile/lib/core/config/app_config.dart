import 'package:flutter/foundation.dart';

/// Build-time settings, passed with `--dart-define`:
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.72:4000/api/v1
/// ```
class AppConfig {
  AppConfig._();

  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Root of the REST API, ending in `/api/v1`.
  ///
  /// Without an override it points at a server on this computer. The Android
  /// emulator reaches the host machine at 10.0.2.2, everything else at
  /// localhost. A real phone needs the computer's LAN address instead.
  static String get apiBaseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? 'http://10.0.2.2:4000/api/v1' : 'http://localhost:4000/api/v1';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Release builds must talk to the API over HTTPS. Plain HTTP is only
  /// allowed while developing against a local server.
  static void assertSecureBaseUrl() {
    if (kReleaseMode && !apiBaseUrl.startsWith('https://')) {
      throw StateError('API_BASE_URL must use https:// in release builds (got $apiBaseUrl).');
    }
  }
}
