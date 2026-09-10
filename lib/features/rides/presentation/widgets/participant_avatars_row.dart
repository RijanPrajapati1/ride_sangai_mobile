import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_avatar.dart';

class ParticipantAvatarsRow extends StatelessWidget {
  final List<String> avatarUrls;
  final int totalCount;
  final VoidCallback? onTap;

  const ParticipantAvatarsRow({
    super.key,
    required this.avatarUrls,
    required this.totalCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shown = avatarUrls.take(5).toList();
    final remaining = totalCount - shown.length;
    final tokens = context.appColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: shown.isEmpty ? 0 : (shown.length * 22.0 + 10),
            height: 32,
            child: Stack(
              children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * 22.0,
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: tokens.surface),
                      padding: const EdgeInsets.all(1.5),
                      child: AppAvatar(imageUrl: shown[i], name: 'Rider', size: 29),
                    ),
                  ),
              ],
            ),
          ),
          if (remaining > 0)
            Text('+$remaining more', style: AppTextStyles.bodySm.copyWith(color: tokens.textSecondary))
          else if (totalCount > 0)
            Text('$totalCount joined', style: AppTextStyles.bodySm.copyWith(color: tokens.textSecondary)),
        ],
      ),
    );
  }
}
