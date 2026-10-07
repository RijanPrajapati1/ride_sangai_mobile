import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yatrix/app/providers/app_providers.dart';
import 'package:yatrix/core/constants/app_constants.dart';
import 'package:yatrix/features/settings/presentation/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> containerWith(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}

void main() {
  test('first launch starts in light mode, even if the phone is in dark mode', () async {
    final container = await containerWith({});
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('a choice made in Settings is remembered', () async {
    final container = await containerWith({});
    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);

    final restarted = await containerWith({AppConstants.themeModeKey: 'dark'});
    expect(restarted.read(themeModeProvider), ThemeMode.dark);
  });

  test('a theme saved by an older version is ignored', () async {
    final container = await containerWith({'theme_mode': 'system'});
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
