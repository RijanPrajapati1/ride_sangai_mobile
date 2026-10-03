import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../domain/entities/conversation.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationTile({super.key, required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd, vertical: AppDimensions.spaceSm),
        child: Row(
          children: [
            AppAvatar(imageUrl: conversation.userAvatarUrl, name: conversation.userName, size: AppDimensions.avatarLg),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conversation.userName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                          color: unread ? Theme.of(context).textTheme.titleMedium?.color : null,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(conversation.lastMessageTime.timeAgo, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                if (unread) AppBadge(count: conversation.unreadCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
