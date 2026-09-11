import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimensions.dart';
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
                const SizedBox(height: 2),
                Text('Ready for your next ride?', style: Theme.of(context).textTheme.bodyMedium),
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
