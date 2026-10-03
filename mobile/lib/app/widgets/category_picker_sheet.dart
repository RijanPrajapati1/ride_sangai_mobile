import 'package:flutter/material.dart';

import '../../core/enums/dashboard_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_ext.dart';
import '../theme/app_dimensions.dart';

/// Opened from the floating center button on the bottom nav. Lets the rider
/// jump between activity dashboards — icon on top, name below, tap to switch.
class CategoryPickerSheet extends StatelessWidget {
  final DashboardCategory selected;
  final ValueChanged<DashboardCategory> onSelected;

  const CategoryPickerSheet({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceLg,
          AppDimensions.spaceLg,
          AppDimensions.spaceLg,
          AppDimensions.spaceXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch Dashboard', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              'Choose the activity you want to organize and ride with today.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            Row(
              children: [
                for (final category in DashboardCategory.values) ...[
                  Expanded(
                    child: _CategoryTile(
                      category: category,
                      isSelected: category == selected,
                      onTap: () => onSelected(category),
                    ),
                  ),
                  if (category != DashboardCategory.values.last) const SizedBox(width: AppDimensions.spaceSm),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final DashboardCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd, horizontal: AppDimensions.spaceXs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : tokens.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: isSelected ? AppColors.primary : tokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: isSelected ? Colors.white : AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              category.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected ? Colors.white : tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
