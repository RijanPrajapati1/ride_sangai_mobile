import 'package:flutter/material.dart';

import '../../app/theme/app_dimensions.dart';
import 'app_avatar.dart';

class UserTile extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const UserTile({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
        child: Row(
          children: [
            AppAvatar(imageUrl: avatarUrl, name: name, size: AppDimensions.avatarMd),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: AppDimensions.spaceSm), trailing!],
          ],
        ),
      ),
    );
  }
}
