import 'package:flutter/material.dart';

import '../../app/theme/app_colors_ext.dart';
import '../../app/theme/app_dimensions.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;

  const StatCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class StatCardRow extends StatelessWidget {
  final List<StatCard> stats;

  const StatCardRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final border = context.appColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0) SizedBox(height: 32, child: VerticalDivider(width: 1, color: border)),
            Expanded(child: stats[i]),
          ],
        ],
      ),
    );
  }
}
