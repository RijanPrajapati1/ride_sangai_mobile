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
  newRideRequest,
  placeReview,

  /// Sent to every rider by the Yatrix team from the admin dashboard.
  announcement,

  /// Fallback for types a newer server sends that this app doesn't know yet.
  other,
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
        NotificationType.newRideRequest => Icons.how_to_reg,
        NotificationType.placeReview => Icons.rate_review,
        NotificationType.announcement => Icons.campaign,
        NotificationType.other => Icons.notifications,
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
        NotificationType.newRideRequest => AppColors.primary,
        NotificationType.placeReview => AppColors.warning,
        NotificationType.announcement => AppColors.secondary,
        NotificationType.other => AppColors.info,
      };
}
