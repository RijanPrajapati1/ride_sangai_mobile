import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_ext.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

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

/// Bottom nav with a notch at the center for the shell's floating action
/// button (see [AppShell]) — pair with `floatingActionButtonLocation:
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
      elevation: 8,
      shadowColor: AppColors.shadow,
      surfaceTintColor: Colors.transparent,
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
    final color = selected ? AppColors.primary : context.appColors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The pill behind the active icon makes the current tab obvious
            // at a glance, not just by a color shift.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    selected ? item.activeIcon : item.icon,
                    color: color,
                    size: 24,
                  ),
                  if (item.trailingBadge != null)
                    Positioned(right: 6, top: -2, child: item.trailingBadge!),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
