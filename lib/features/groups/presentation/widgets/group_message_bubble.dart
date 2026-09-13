import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../domain/entities/group_message.dart';

class GroupMessageBubble extends StatelessWidget {
  final GroupMessage message;

  const GroupMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final tokens = context.appColors;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : tokens.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimensions.radiusLg),
            topRight: const Radius.circular(AppDimensions.radiusLg),
            bottomLeft: Radius.circular(isMe ? AppDimensions.radiusLg : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppDimensions.radiusLg),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) ...[
              Text(
                message.senderName,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : tokens.textPrimary, fontSize: 14.5),
            ),
            const SizedBox(height: 4),
            Text(
              message.sentAt.toChatTimestamp,
              style: TextStyle(
                fontSize: 10.5,
                color: isMe ? Colors.white.withValues(alpha: 0.75) : tokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
