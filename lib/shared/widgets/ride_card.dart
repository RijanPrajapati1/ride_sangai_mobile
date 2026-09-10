import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../core/enums/ride_enums.dart';
import '../../core/extensions/date_time_extensions.dart';
import '../../features/rides/domain/entities/ride.dart';
import 'app_avatar.dart';
import 'app_chip.dart';
import 'app_network_image.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback? onTap;
  final bool large;

  const RideCard({super.key, required this.ride, this.onTap, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  url: ride.imageUrl,
                  height: large ? 180 : 130,
                  width: double.infinity,
                  fallbackIcon: ride.rideType.icon,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: AppChip(
                    label: ride.difficulty.label,
                    color: ride.difficulty.color,
                    selected: true,
                  ),
                ),
                if (_statusLabel != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      ),
                      child: Text(
                        _statusLabel!,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text('${ride.date.relativeDayLabel} · ${ride.date.toTime}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ride.meetingPoint,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  Row(
                    children: [
                      AppAvatar(imageUrl: ride.organizerAvatarUrl, name: ride.organizerName, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.organizerName,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.groups_outlined, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${ride.participantCount}/${ride.maxParticipants}',
                          style: Theme.of(context).textTheme.bodySmall),
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

  String? get _statusLabel => switch (ride.joinStatus) {
        RideJoinStatus.organizer => 'Organizing',
        RideJoinStatus.approved => 'Joined',
        RideJoinStatus.pending => 'Requested',
        RideJoinStatus.declined => 'Declined',
        RideJoinStatus.none => null,
      };
}
