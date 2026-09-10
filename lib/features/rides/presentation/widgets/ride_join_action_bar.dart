import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/ride.dart';

/// Bottom action bar on the ride details screen. Renders the correct action
/// (request / pending / joined / organizer) based on [ride.joinStatus].
class RideJoinActionBar extends StatelessWidget {
  final Ride ride;
  final bool isLoading;
  final VoidCallback onRequestToJoin;
  final VoidCallback onCancelRequest;
  final VoidCallback onManageRequests;
  final VoidCallback onMessageOrganizer;

  const RideJoinActionBar({
    super.key,
    required this.ride,
    required this.isLoading,
    required this.onRequestToJoin,
    required this.onCancelRequest,
    required this.onManageRequests,
    required this.onMessageOrganizer,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: onMessageOrganizer,
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Message organizer',
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(child: _buildPrimaryAction(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    switch (ride.joinStatus) {
      case RideJoinStatus.organizer:
        return AppButton(label: 'Manage Requests', icon: Icons.groups_2_outlined, onPressed: onManageRequests);
      case RideJoinStatus.approved:
        return AppOutlinedButton(
          label: "You're Going · Leave Ride",
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          onPressed: isLoading ? null : onCancelRequest,
        );
      case RideJoinStatus.pending:
        return AppOutlinedButton(
          label: 'Request Pending · Cancel',
          icon: Icons.hourglass_top_outlined,
          color: AppColors.warning,
          onPressed: isLoading ? null : onCancelRequest,
        );
      case RideJoinStatus.declined:
      case RideJoinStatus.none:
        if (ride.isFull) {
          return const AppButton(label: 'Ride Full', onPressed: null);
        }
        return AppButton(
          label: 'Request to Join',
          icon: Icons.pedal_bike,
          isLoading: isLoading,
          onPressed: onRequestToJoin,
        );
    }
  }
}
