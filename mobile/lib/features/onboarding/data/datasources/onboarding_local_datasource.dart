import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

class OnboardingLocalDataSource {
  final SharedPreferences _prefs;

  OnboardingLocalDataSource(this._prefs);

  Future<bool> isComplete() async {
    return _prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
  }

  Future<void> complete() async {
    await _prefs.setBool(AppConstants.onboardingCompleteKey, true);
  }
}
