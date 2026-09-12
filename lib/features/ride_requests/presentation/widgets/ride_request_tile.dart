import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../domain/entities/ride_request.dart';

class RideRequestTile extends StatelessWidget {
  final RideRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onTap;

  const RideRequestTile({
    super.key,
    required this.request,
    this.onApprove,
    this.onDecline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(imageUrl: request.userAvatarUrl, name: request.userName, size: 48),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.userName, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(request.userBio, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            AppChip(label: request.experienceLevel.label, icon: Icons.emoji_events_outlined),
                            AppChip(
                              label: request.status.label,
                              color: request.status.color,
                              selected: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Requested ${request.requestedAt.timeAgo}', style: Theme.of(context).textTheme.bodySmall),
              if (request.status == RideRequestStatus.declined &&
                  request.declineReason != null &&
                  request.declineReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spaceSm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          request.declineReason!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (request.status == RideRequestStatus.pending && (onApprove != null || onDecline != null)) ...[
                const SizedBox(height: AppDimensions.spaceSm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Expanded(
                      child: ElevatedButton(onPressed: onApprove, child: const Text('Approve')),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
