import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum NotificationType {
  requestApproved,
  requestDeclined,
  newMessage,
  rideReminder,
  rideUpdated,
  newFollower,
  comment,
  like,
}

extension NotificationTypeX on NotificationType {
  IconData get icon => switch (this) {
        NotificationType.requestApproved => Icons.check_circle,
        NotificationType.requestDeclined => Icons.cancel,
        NotificationType.newMessage => Icons.chat_bubble,
        NotificationType.rideReminder => Icons.alarm,
        NotificationType.rideUpdated => Icons.edit_calendar,
        NotificationType.newFollower => Icons.person_add_alt_1,
        NotificationType.comment => Icons.mode_comment,
        NotificationType.like => Icons.favorite,
      };

  Color get color => switch (this) {
        NotificationType.requestApproved => AppColors.success,
        NotificationType.requestDeclined => AppColors.error,
        NotificationType.newMessage => AppColors.info,
        NotificationType.rideReminder => AppColors.secondary,
        NotificationType.rideUpdated => AppColors.warning,
        NotificationType.newFollower => AppColors.primary,
        NotificationType.comment => AppColors.info,
        NotificationType.like => AppColors.error,
      };
}
