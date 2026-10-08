import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../profile/domain/entities/user_profile.dart';

class RecommendedRiderCard extends StatelessWidget {
  final UserProfile rider;
  final VoidCallback onTap;
  final VoidCallback onFollow;

  const RecommendedRiderCard({
    super.key,
    required this.rider,
    required this.onTap,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    final theme = Theme.of(context);
    final following = rider.isFollowing;
    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceSm),
            child: Column(
              children: [
                AppAvatar(imageUrl: rider.avatarUrl, name: rider.name, size: 60),
                const SizedBox(height: 8),
                Text(
                  rider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  rider.location.isNotEmpty ? rider.location : rider.experienceLevel.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: following
                      ? OutlinedButton(
                          onPressed: onFollow,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 34),
                            foregroundColor: tokens.textSecondary,
                            side: BorderSide(color: tokens.border),
                            textStyle: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700),
                          ),
                          child: const Text('Following'),
                        )
                      : FilledButton.icon(
                          onPressed: onFollow,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 34),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            foregroundColor: AppColors.primary,
                            textStyle: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                          ),
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                          label: const Text('Follow'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
