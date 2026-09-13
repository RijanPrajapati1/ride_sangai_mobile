import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/group.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback? onTap;
  final VoidCallback? onJoinToggle;
  final bool joinBusy;

  const GroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.onJoinToggle,
    this.joinBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = context.appColors.textMuted;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(
              url: group.coverImageUrl,
              height: 110,
              width: double.infinity,
              fallbackIcon: Icons.groups_outlined,
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  Row(
                    children: [
                      Icon(Icons.groups_outlined, size: 15, color: textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('${group.memberCount} members', style: Theme.of(context).textTheme.bodySmall),
                      ),
                      if (onJoinToggle != null)
                        SizedBox(
                          width: 84,
                          height: 32,
                          child: group.isJoined
                              ? OutlinedButton(
                                  onPressed: joinBusy ? null : onJoinToggle,
                                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                                  child: const Text('Joined'),
                                )
                              : FilledButton(
                                  onPressed: joinBusy ? null : onJoinToggle,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Join'),
                                ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
