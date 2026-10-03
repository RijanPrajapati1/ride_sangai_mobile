import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../domain/entities/place_review.dart';
import 'rating_stars.dart';

class ReviewTile extends StatelessWidget {
  final PlaceReview review;
  final VoidCallback? onAuthorTap;

  const ReviewTile({super.key, required this.review, this.onAuthorTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onAuthorTap,
            child: AppAvatar(imageUrl: review.userAvatarUrl, name: review.userName, size: 40),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.isMine ? '${review.userName} (you)' : review.userName,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(review.createdAt.timeAgo, style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    RatingStars(rating: review.rating.toDouble(), size: 14),
                    const SizedBox(width: 8),
                    Icon(
                      review.worthIt ? Icons.thumb_up_alt_outlined : Icons.thumb_down_alt_outlined,
                      size: 14,
                      color: review.worthIt ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.worthIt ? 'Worth it' : 'Not worth it',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: review.worthIt ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (review.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(review.text, style: theme.textTheme.bodyMedium),
                ],
                if (review.visitedOn != null) ...[
                  const SizedBox(height: 4),
                  Text('Visited ${review.visitedOn!.toMonthDay}', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
