import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/community_post.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onAuthorTap;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              child: InkWell(
                onTap: onAuthorTap,
                child: Row(
                  children: [
                    AppAvatar(imageUrl: post.userAvatarUrl, name: post.userName, size: 44),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.userName, style: Theme.of(context).textTheme.titleMedium),
                          Text(post.time.timeAgo, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
              child: Text(post.text, style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (post.imageUrl != null) ...[
              const SizedBox(height: AppDimensions.spaceSm),
              AppNetworkImage(url: post.imageUrl, height: 200, width: double.infinity),
            ],
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceSm),
              child: Row(
                children: [
                  _ActionButton(
                    icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${post.likeCount}',
                    color: post.isLiked ? AppColors.error : null,
                    onTap: onLike,
                  ),
                  _ActionButton(icon: Icons.mode_comment_outlined, label: '${post.commentCount}', onTap: onComment),
                  _ActionButton(icon: Icons.share_outlined, label: 'Share', onTap: onShare),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color ?? context.appColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
