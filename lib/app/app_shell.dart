import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/enums/dashboard_category.dart';
import '../features/messages/presentation/providers/message_providers.dart';
import '../shared/widgets/app_badge.dart';
import '../shared/widgets/app_bottom_navigation.dart';
import 'providers/dashboard_category_provider.dart';
import 'router/route_names.dart';
import 'theme/app_colors.dart';
import 'widgets/category_picker_sheet.dart';

/// Authenticated app shell hosting the five bottom-navigation tabs, plus a
/// floating center button that opens the activity-dashboard switcher. Each
/// tab keeps its own navigation stack via [StatefulShellRoute.indexedStack].
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  Future<void> _openCategoryPicker(BuildContext context, WidgetRef ref) async {
    final category = ref.read(selectedDashboardCategoryProvider);
    // The sheet only pops itself with a result; switching state and
    // navigating happens below using the shell's own (still-valid) context,
    // never the sheet's context, which is mid-teardown once it pops.
    final selected = await showModalBottomSheet<DashboardCategory>(
      context: context,
      builder: (sheetContext) => CategoryPickerSheet(
        selected: category,
        onSelected: (picked) => Navigator.of(sheetContext).pop(picked),
      ),
    );
    if (selected != null && context.mounted) {
      ref.read(selectedDashboardCategoryProvider.notifier).state = selected;
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadMessages = ref.watch(totalUnreadMessagesProvider);
    final category = ref.watch(selectedDashboardCategoryProvider);

    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategoryPicker(context, ref),
        backgroundColor: AppColors.primary,
        tooltip: 'Switch dashboard',
        child: Icon(category.icon, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          const AppBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          AppBottomNavItem(icon: category.icon, activeIcon: category.icon, label: category.activityNoun),
          const AppBottomNavItem(icon: Icons.groups_outlined, activeIcon: Icons.groups, label: 'Community'),
          AppBottomNavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Messages',
            trailingBadge: unreadMessages > 0 ? AppBadge(count: unreadMessages) : null,
          ),
          const AppBottomNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}
