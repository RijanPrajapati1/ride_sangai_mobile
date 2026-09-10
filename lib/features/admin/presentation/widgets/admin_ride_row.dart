import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../rides/domain/entities/ride.dart';

class AdminRideRow extends StatelessWidget {
  final Ride ride;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AdminRideRow({super.key, required this.ride, required this.onTap, required this.onDelete});

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
              AppAvatar(imageUrl: ride.organizerAvatarUrl, name: ride.organizerName, size: 40),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'By ${ride.organizerName} · ${ride.date.relativeDayLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        AppChip(label: ride.difficulty.label, color: ride.difficulty.color, selected: true),
                        AppChip(label: '${ride.participantCount}/${ride.maxParticipants}', icon: Icons.groups_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Delete ride',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
