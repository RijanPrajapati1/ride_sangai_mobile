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

  /// Image URLs from the API are built from the server's `PUBLIC_URL`. In
  /// development that is often `http://localhost:4000`, which a phone or the
  /// Android emulator can't reach. Such URLs are pointed at the host the app
  /// already uses for the API. Every other URL is returned unchanged.
  static String mediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !const {'localhost', '127.0.0.1'}.contains(uri.host)) return url;
    final api = Uri.parse(apiBaseUrl);
    if (api.host == uri.host) return url;
    return uri.replace(scheme: api.scheme, host: api.host, port: api.port).toString();
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
