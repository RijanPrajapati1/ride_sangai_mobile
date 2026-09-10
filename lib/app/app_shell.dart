import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/messages/presentation/providers/message_providers.dart';
import '../shared/widgets/app_badge.dart';
import '../shared/widgets/app_bottom_navigation.dart';

/// Authenticated app shell hosting the five bottom-navigation tabs. Each
/// branch keeps its own navigation stack via [StatefulShellRoute.indexedStack].
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadMessages = ref.watch(totalUnreadMessagesProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          const AppBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          const AppBottomNavItem(icon: Icons.pedal_bike_outlined, activeIcon: Icons.pedal_bike, label: 'Rides'),
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
