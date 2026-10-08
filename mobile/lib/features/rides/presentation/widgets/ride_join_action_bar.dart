import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';
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
    final tokens = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.border.withValues(alpha: 0.6))),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Row(
            children: [
              if (!ride.isOrganizer) ...[
                SizedBox(
                  width: AppDimensions.buttonHeight,
                  height: AppDimensions.buttonHeight,
                  child: IconButton.filledTonal(
                    onPressed: onMessageOrganizer,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    tooltip: 'Message organizer',
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
              ],
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
        if (ride.hasStarted) {
          return AppButton(label: ride.hasEnded ? 'Ride Ended' : 'Ride In Progress', onPressed: null);
        }
        if (ride.isFull) {
          return const AppButton(label: 'Ride Full', onPressed: null);
        }
        return AppButton(
          label: ride.joinStatus == RideJoinStatus.declined ? 'Ask Again' : 'Request to Join',
          icon: ride.rideType.category.icon,
          isLoading: isLoading,
          onPressed: onRequestToJoin,
        );
    }
  }
}
