import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../domain/entities/comment.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onLike;

  /// Shown when set (the comment's author or the post's author may delete).
  final VoidCallback? onDelete;

  const CommentTile({super.key, required this.comment, this.onLike, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(imageUrl: comment.userAvatarUrl, name: comment.userName, size: 36),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.userName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(comment.time.timeAgo, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    InkWell(
                      onTap: onLike,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              comment.isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: comment.isLiked ? AppColors.error : null,
                            ),
                            const SizedBox(width: 4),
                            Text('${comment.likeCount}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: AppDimensions.spaceMd),
                      InkWell(
                        onTap: onDelete,
                        child: Text('Delete', style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
