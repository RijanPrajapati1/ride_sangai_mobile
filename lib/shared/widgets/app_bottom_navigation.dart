import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_ext.dart';
import '../../app/theme/app_dimensions.dart';

class AppBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget? trailingBadge;

  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.trailingBadge,
  });
}

/// Bottom nav with a notch left of center for the shell's floating category
/// switcher (see [AppShell]) — pair with `floatingActionButtonLocation:
/// FloatingActionButtonLocation.centerDocked`.
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      // Must differ from the scaffold background, or the notch Material cuts
      // for the FAB has no contrast against it and never reads as a curve.
      color: context.appColors.surface,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      // A visible elevation lets Material's shadow trace the notch's curve,
      // instead of a straight border that would cut across it and hide it.
      elevation: 6,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Expanded(
                  child: _NavItem(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
                if (i == 1) const SizedBox(width: AppDimensions.spaceXxl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : context.appColors.textMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                color: color,
                size: 24,
              ),
              if (item.trailingBadge != null)
                Positioned(right: -6, top: -4, child: item.trailingBadge!),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
