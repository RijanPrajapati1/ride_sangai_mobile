import 'package:flutter/material.dart';

import '../../app/theme/app_colors_ext.dart';
import '../../app/theme/app_dimensions.dart';
import '../../core/enums/notification_type.dart';
import '../../core/extensions/date_time_extensions.dart';
import '../../features/notifications/domain/entities/notification_item.dart';
import 'app_avatar.dart';
import 'app_badge.dart';

class NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead ? Colors.transparent : context.appColors.primaryLight.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd, vertical: AppDimensions.spaceSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.actorAvatarUrl != null)
              AppAvatar(imageUrl: notification.actorAvatarUrl, name: notification.title, size: 44)
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.type.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(notification.type.icon, color: notification.type.color, size: 20),
              ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(notification.description, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(notification.time.timeAgo, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (!notification.isRead) const Padding(
              padding: EdgeInsets.only(left: 8, top: 6),
              child: AppDot(),
            ),
          ],
        ),
      ),
    );
  }
}
