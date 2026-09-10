import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_network_image.dart';

const demoCoverOptions = [
  'https://picsum.photos/seed/cover-a/900/600',
  'https://picsum.photos/seed/cover-b/900/600',
  'https://picsum.photos/seed/cover-c/900/600',
  'https://picsum.photos/seed/cover-d/900/600',
];

/// Demo cover-photo selector — picks from a small placeholder gallery since
/// real gallery/upload access isn't wired up yet.
class CoverImagePicker extends StatelessWidget {
  final String? imageUrl;
  final ValueChanged<String> onChanged;

  const CoverImagePicker({super.key, required this.imageUrl, required this.onChanged});

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
              Text('Choose a cover photo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppDimensions.spaceMd),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  for (final url in demoCoverOptions)
                    InkWell(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      onTap: () => Navigator.of(context).pop(url),
                      child: AppNetworkImage(
                        url: url,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        height: 150,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: imageUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 30),
                  const SizedBox(height: 6),
                  Text('Add cover photo', style: Theme.of(context).textTheme.bodyMedium),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: imageUrl),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
