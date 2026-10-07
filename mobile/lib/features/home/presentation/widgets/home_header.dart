import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_badge.dart';

class HomeHeader extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final int unreadNotifications;
  final int unreadMessages;
  final DashboardCategory category;
  final ValueChanged<DashboardCategory> onCategoryChanged;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onMessagesTap;

  const HomeHeader({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.unreadNotifications,
    required this.unreadMessages,
    required this.category,
    required this.onCategoryChanged,
    required this.onAvatarTap,
    required this.onNotificationsTap,
    required this.onMessagesTap,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceMd,
        AppDimensions.spaceSm,
        AppDimensions.spaceMd,
        AppDimensions.spaceMd,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: AppAvatar(imageUrl: avatarUrl, name: name, size: AppDimensions.avatarLg),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_greeting, $firstName 👋', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                _DashboardDropdown(selected: category, onChanged: onCategoryChanged),
              ],
            ),
          ),
          InkWell(
            onTap: onMessagesTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 24),
                  if (unreadMessages > 0)
                    Positioned(right: -4, top: -4, child: AppBadge(count: unreadMessages)),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onNotificationsTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined, size: 26),
                  if (unreadNotifications > 0)
                    Positioned(right: -4, top: -4, child: AppBadge(count: unreadNotifications)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill showing the active dashboard; tapping it opens a menu to switch.
class _DashboardDropdown extends StatelessWidget {
  final DashboardCategory selected;
  final ValueChanged<DashboardCategory> onChanged;

  const _DashboardDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    return PopupMenuButton<DashboardCategory>(
      tooltip: 'Switch dashboard',
      initialValue: selected,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
      itemBuilder: (context) => [
        for (final category in DashboardCategory.values)
          PopupMenuItem(
            value: category,
            child: Row(
              children: [
                Icon(
                  category.icon,
                  size: 20,
                  color: category == selected ? AppColors.primary : tokens.textSecondary,
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(child: Text(category.label)),
                if (category == selected) const Icon(Icons.check, size: 18, color: AppColors.primary),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected.icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              selected.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
