import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../community/domain/entities/community_post.dart';

class AdminPostRow extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onDelete;

  const AdminPostRow({super.key, required this.post, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final textMuted = context.appColors.textMuted;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(imageUrl: post.userAvatarUrl, name: post.userName, size: 40),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(post.userName, style: Theme.of(context).textTheme.titleMedium)),
                      Text(post.time.timeAgo, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(post.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.favorite_outline, size: 14, color: textMuted),
                      const SizedBox(width: 4),
                      Text('${post.likeCount}', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.mode_comment_outlined, size: 14, color: textMuted),
                      const SizedBox(width: 4),
                      Text('${post.commentCount}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Delete post',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
