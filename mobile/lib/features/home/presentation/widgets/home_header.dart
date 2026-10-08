import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_badge.dart';

class HomeHeader extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final int unreadNotifications;
  final int unreadMessages;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onMessagesTap;

  const HomeHeader({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.unreadNotifications,
    required this.unreadMessages,
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
    final tokens = context.appColors;
    final firstName = name.split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceMd,
        AppDimensions.spaceSm,
        AppDimensions.spaceMd,
        AppDimensions.spaceSm,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Your profile',
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: AppColors.heroGradient),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: tokens.background),
                  child: AppAvatar(imageUrl: avatarUrl, name: name, size: 44),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_greeting 👋', style: AppTextStyles.bodyMd.copyWith(color: tokens.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd.copyWith(color: tokens.textPrimary),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Messages',
            count: unreadMessages,
            onTap: onMessagesTap,
          ),
          const SizedBox(width: AppDimensions.spaceXs),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            count: unreadNotifications,
            onTap: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

/// Round, outlined icon button with an unread badge.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final int count;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.tooltip, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    return Tooltip(
      message: count > 0 ? '$tooltip ($count unread)' : tooltip,
      child: Material(
        color: tokens.surface,
        shape: CircleBorder(side: BorderSide(color: tokens.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: tokens.textPrimary),
                if (count > 0) Positioned(right: 4, top: 4, child: AppBadge(count: count)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The four activity dashboards as one row of chips, so riders can see every
/// option and switch with a single tap.
class DashboardCategoryChips extends StatelessWidget {
  final DashboardCategory selected;
  final ValueChanged<DashboardCategory> onChanged;

  const DashboardCategoryChips({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
        itemCount: DashboardCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.spaceXs),
        itemBuilder: (context, index) {
          final category = DashboardCategory.values[index];
          return _CategoryChip(
            category: category,
            selected: category == selected,
            onTap: () => onChanged(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final DashboardCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    final foreground = selected ? Colors.white : tokens.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primary : tokens.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : tokens.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 18, color: selected ? Colors.white : AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  category.label,
                  style: AppTextStyles.labelLg.copyWith(color: foreground, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
