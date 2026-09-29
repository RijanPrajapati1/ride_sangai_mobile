import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/user_tile.dart';
import '../../../profile/domain/entities/user_profile.dart';

class AdminUserRow extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const AdminUserRow({super.key, required this.user, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: UserTile(
        avatarUrl: user.avatarUrl,
        name: user.name,
        subtitle: '${user.location} · ${user.totalRides} rides',
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppChip(label: user.experienceLevel.label),
            IconButton(
              icon: const Icon(Icons.person_remove_outlined, color: AppColors.error),
              tooltip: 'Remove rider',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
