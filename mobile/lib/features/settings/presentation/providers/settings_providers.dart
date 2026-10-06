import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/constants/app_constants.dart';

class ThemeModeController extends StateNotifier<ThemeMode> {
  final Ref _ref;

  ThemeModeController(this._ref) : super(_read(_ref));

  static ThemeMode _read(Ref ref) {
    final saved = ref.read(sharedPreferencesProvider).getString(AppConstants.themeModeKey);
    return switch (saved) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      // First launch: start in light mode. Users can pick Dark or System in Settings.
      _ => ThemeMode.light,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _ref.read(sharedPreferencesProvider).setString(AppConstants.themeModeKey, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref);
});
