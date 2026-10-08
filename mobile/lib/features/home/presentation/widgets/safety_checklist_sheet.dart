import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/enums/dashboard_category.dart';

typedef _Tip = ({IconData icon, String title, String detail});

List<_Tip> _tipsFor(DashboardCategory category) => switch (category) {
      DashboardCategory.cycling => const [
          (icon: Icons.sports_motorsports_outlined, title: 'Wear a certified helmet', detail: 'Strap snug, two fingers above your eyebrows.'),
          (icon: Icons.flashlight_on_outlined, title: 'Front and rear lights', detail: 'Charged, and on for dawn starts and tunnels.'),
          (icon: Icons.build_outlined, title: 'Quick bike check', detail: 'Brakes, tyre pressure and a spare tube.'),
          (icon: Icons.water_drop_outlined, title: 'Water and a snack', detail: 'At least a litre, more for climbs.'),
          (icon: Icons.share_location_outlined, title: 'Share your route', detail: 'Let someone at home know where you are riding.'),
        ],
      DashboardCategory.trekking => const [
          (icon: Icons.trending_up_rounded, title: 'Acclimatize as you climb', detail: 'Above 3,000 m, gain sleeping altitude slowly.'),
          (icon: Icons.cloud_outlined, title: 'Check the weather', detail: 'Mountain weather turns fast; plan a turnaround time.'),
          (icon: Icons.badge_outlined, title: 'Carry your permits', detail: 'Keep trekking permits and ID within reach.'),
          (icon: Icons.layers_outlined, title: 'Pack layers and rain gear', detail: 'Warm layer, shell jacket and a hat.'),
          (icon: Icons.share_location_outlined, title: 'Share your itinerary', detail: 'Leave your route and return date with someone.'),
        ],
      DashboardCategory.hiking => const [
          (icon: Icons.water_drop_outlined, title: 'Bring enough water', detail: 'Plan for half a litre per hour of hiking.'),
          (icon: Icons.map_outlined, title: 'Download the map', detail: 'Phone signal drops on most trails.'),
          (icon: Icons.hiking_rounded, title: 'Wear proper footwear', detail: 'Shoes with grip, broken in before the hike.'),
          (icon: Icons.wb_sunny_outlined, title: 'Start early', detail: 'Finish well before dark, with time to spare.'),
          (icon: Icons.share_location_outlined, title: 'Tell someone your plan', detail: 'Where you are going and when you will be back.'),
        ],
      DashboardCategory.riding => const [
          (icon: Icons.sports_motorsports_outlined, title: 'Full riding gear', detail: 'Certified helmet, gloves, jacket and boots.'),
          (icon: Icons.build_outlined, title: 'Check your bike', detail: 'Tyres, brakes, chain and lights before you leave.'),
          (icon: Icons.social_distance_outlined, title: 'Keep a safe gap', detail: 'Ride staggered and never overtake the lead.'),
          (icon: Icons.local_cafe_outlined, title: 'Ride rested and sober', detail: 'Take a break every hour on long rides.'),
          (icon: Icons.description_outlined, title: 'Carry your papers', detail: 'Licence, bluebook and insurance.'),
        ],
    };

/// Bottom sheet with a short safety checklist for [category].
Future<void> showSafetyChecklistSheet(BuildContext context, DashboardCategory category) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SafetyChecklist(category: category),
  );
}

class _SafetyChecklist extends StatelessWidget {
  final DashboardCategory category;

  const _SafetyChecklist({required this.category});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceLg,
          0,
          AppDimensions.spaceLg,
          AppDimensions.spaceLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(Icons.health_and_safety_rounded, color: AppColors.secondary),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safety checklist', style: AppTextStyles.titleLg.copyWith(color: tokens.textPrimary)),
                      Text(
                        'Before every ${category.activitySingular.toLowerCase()}',
                        style: AppTextStyles.bodySm.copyWith(color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            for (final tip in _tipsFor(category))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tip.icon, size: 22, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip.title, style: AppTextStyles.labelLg.copyWith(color: tokens.textPrimary)),
                          const SizedBox(height: 2),
                          Text(tip.detail, style: AppTextStyles.bodyMd.copyWith(color: tokens.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppDimensions.spaceMd),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
