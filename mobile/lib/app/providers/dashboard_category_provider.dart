import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/enums/dashboard_category.dart';
import 'app_providers.dart';

/// Holds the active dashboard and remembers it across launches, so riders
/// land on the activity they care about instead of always on Cycling.
class DashboardCategoryController extends StateNotifier<DashboardCategory> {
  static const _storageKey = 'selected_dashboard_category';

  final SharedPreferences _prefs;

  DashboardCategoryController(this._prefs) : super(_restore(_prefs));

  static DashboardCategory _restore(SharedPreferences prefs) {
    final saved = prefs.getString(_storageKey);
    return DashboardCategory.values.firstWhere(
      (category) => category.name == saved,
      orElse: () => DashboardCategory.cycling,
    );
  }

  void select(DashboardCategory category) {
    if (category == state) return;
    state = category;
    _prefs.setString(_storageKey, category.name);
  }
}

/// Which activity dashboard (Cycling, Trekking, Hiking, Riding) is active.
/// Switched from the dropdown at the top of Home. Read by every rides
/// provider/screen that needs to scope its data to it.
final selectedDashboardCategoryProvider =
    StateNotifierProvider<DashboardCategoryController, DashboardCategory>((ref) {
  return DashboardCategoryController(ref.watch(sharedPreferencesProvider));
});
