import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_sangai/core/config/app_config.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('points localhost image URLs at the emulator host on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(AppConfig.mediaUrl('http://localhost:4000/uploads/a.jpg'), 'http://10.0.2.2:4000/uploads/a.jpg');
  });

  test('leaves other image URLs alone', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(AppConfig.mediaUrl('https://cdn.example.com/a.jpg'), 'https://cdn.example.com/a.jpg');
    expect(AppConfig.mediaUrl(''), '');
  });

  test('keeps localhost URLs when the app itself talks to localhost', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(AppConfig.mediaUrl('http://localhost:4000/uploads/a.jpg'), 'http://localhost:4000/uploads/a.jpg');
  });
}
