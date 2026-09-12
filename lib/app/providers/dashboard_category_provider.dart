import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/dashboard_category.dart';

/// Which activity dashboard (Cycling, Trekking, Hiking, Riding) is active.
/// Read by the bottom nav shell (the floating switcher + tab labels) and by
/// every rides provider/screen that needs to scope its data to it.
final selectedDashboardCategoryProvider = StateProvider<DashboardCategory>((ref) {
  return DashboardCategory.cycling;
});
