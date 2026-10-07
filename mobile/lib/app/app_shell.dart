import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/enums/dashboard_category.dart';
import '../shared/widgets/app_bottom_navigation.dart';
import 'providers/dashboard_category_provider.dart';

/// Authenticated app shell hosting the bottom-navigation tabs. The activity
/// dashboard is switched from the dropdown at the top of Home. Each tab keeps
/// its own navigation stack via [StatefulShellRoute.indexedStack].
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(selectedDashboardCategoryProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          const AppBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          AppBottomNavItem(
            icon: category.icon,
            activeIcon: category.icon,
            label: category.activityNoun,
          ),
          const AppBottomNavItem(
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups,
            label: 'Community',
          ),
          const AppBottomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
