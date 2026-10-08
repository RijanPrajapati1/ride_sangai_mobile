import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}

class QuickActions extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final action in actions) Expanded(child: _QuickActionTile(action: action)),
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
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: action.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXs),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(action.icon, color: action.color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(color: context.appColors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
