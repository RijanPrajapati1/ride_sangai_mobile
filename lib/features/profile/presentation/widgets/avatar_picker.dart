import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_network_image.dart';

const demoAvatarOptions = [
  'https://i.pravatar.cc/150?img=5',
  'https://i.pravatar.cc/150?img=8',
  'https://i.pravatar.cc/150?img=11',
  'https://i.pravatar.cc/150?img=20',
  'https://i.pravatar.cc/150?img=33',
  'https://i.pravatar.cc/150?img=50',
  'https://i.pravatar.cc/150?img=60',
  'https://i.pravatar.cc/150?img=65',
];

/// Demo profile-photo selector — picks from a small placeholder gallery
/// since real camera/gallery access isn't wired up yet.
class AvatarPicker extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final ValueChanged<String> onChanged;

  const AvatarPicker({super.key, required this.name, required this.avatarUrl, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose a profile photo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppDimensions.spaceMd),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final url in demoAvatarOptions)
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.of(context).pop(url),
                      child: ClipOval(
                        child: AppNetworkImage(url: url, fallbackIcon: Icons.person),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Stack(
        children: [
          AppAvatar(imageUrl: avatarUrl, name: name, size: AppDimensions.avatarXl),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
