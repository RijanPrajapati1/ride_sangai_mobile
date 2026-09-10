import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../domain/entities/comment.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({super.key, required this.comment});

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
                    Text(comment.userName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 8),
                    Text(comment.time.timeAgo, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 14),
                    const SizedBox(width: 4),
                    Text('${comment.likeCount}', style: Theme.of(context).textTheme.bodySmall),
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
