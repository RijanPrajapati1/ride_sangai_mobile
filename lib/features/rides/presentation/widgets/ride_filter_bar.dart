import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../providers/ride_providers.dart';

class RideFilterBar extends StatelessWidget {
  final RideFilters filters;
  final ValueChanged<RideType?> onTypeChanged;
  final ValueChanged<RideDifficulty?> onDifficultyChanged;

  const RideFilterBar({
    super.key,
    required this.filters,
    required this.onTypeChanged,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
        children: [
          for (final type in RideType.values) ...[
            AppChip(
              label: type.label,
              icon: type.icon,
              selected: filters.type == type,
              onTap: () => onTypeChanged(filters.type == type ? null : type),
            ),
            const SizedBox(width: 8),
          ],
          Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 1, color: Theme.of(context).dividerColor),
          const SizedBox(width: 8),
          for (final difficulty in RideDifficulty.values) ...[
            AppChip(
              label: difficulty.label,
              color: difficulty.color,
              selected: filters.difficulty == difficulty,
              onTap: () => onDifficultyChanged(filters.difficulty == difficulty ? null : difficulty),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
