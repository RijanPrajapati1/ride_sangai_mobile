import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Builds the app's HTTP client: base URL, timeouts, JSON headers and the
/// interceptor chain (auth → logging).
class DioFactory {
  DioFactory._();

  static Dio create({
    required TokenStorage tokenStorage,
    required void Function() onSessionEnded,
    String? baseUrl,
    HttpClientAdapter? adapter,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
        // Browsers don't allow setting User-Agent; the server shows it in the
        // "signed-in devices" list.
        if (!kIsWeb) 'User-Agent': 'RideSangai/1.0 (${defaultTargetPlatform.name})',
      },
    );

    // Refreshing uses its own client without the auth interceptor, so a
    // failing refresh can never trigger another refresh.
    final refreshDio = Dio(options);
    final dio = Dio(options);
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
      refreshDio.httpClientAdapter = adapter;
    }

    dio.interceptors.add(AuthInterceptor(
      dio: dio,
      refreshDio: refreshDio,
      storage: tokenStorage,
      onSessionEnded: onSessionEnded,
    ));
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
      refreshDio.interceptors.add(LoggingInterceptor());
    }
    return dio;
  }
}
