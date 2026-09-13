import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../groups/domain/entities/group.dart';
import '../../../../shared/widgets/app_network_image.dart';

class AdminGroupRow extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AdminGroupRow({super.key, required this.group, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: AppNetworkImage(
                  url: group.coverImageUrl,
                  width: 48,
                  height: 48,
                  fallbackIcon: Icons.groups_outlined,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'By ${group.organizerName} · ${group.memberCount} members',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Delete group',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
