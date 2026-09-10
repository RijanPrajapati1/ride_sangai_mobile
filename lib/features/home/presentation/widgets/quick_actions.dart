import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAction({required this.icon, required this.label, required this.onTap});
}

class QuickActions extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
      child: Row(
        children: [
          for (final action in actions) ...[
            Expanded(child: _QuickActionTile(action: action)),
            if (action != actions.last) const SizedBox(width: AppDimensions.spaceSm),
          ],
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: tokens.primaryLight, shape: BoxShape.circle),
              child: Icon(action.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).textTheme.titleMedium?.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
