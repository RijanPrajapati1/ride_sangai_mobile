import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_network_image.dart';

const demoPlacePhotos = [
  'https://picsum.photos/seed/place-a/900/600',
  'https://picsum.photos/seed/place-b/900/600',
  'https://picsum.photos/seed/place-c/900/600',
  'https://picsum.photos/seed/place-d/900/600',
  'https://picsum.photos/seed/place-e/900/600',
  'https://picsum.photos/seed/place-f/900/600',
];

/// Demo photo selector (up to [max]) from a placeholder gallery, like the ride
/// cover picker; swap for real uploads (POST /api/v1/uploads) later.
class PlacePhotoPicker extends StatelessWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onChanged;
  final int max;

  const PlacePhotoPicker({super.key, required this.photos, required this.onChanged, this.max = 5});

  Future<void> _add(BuildContext context) async {
    final available = demoPlacePhotos.where((url) => !photos.contains(url)).toList();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a photo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppDimensions.spaceMd),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final url in available)
                    InkWell(
                      onTap: () => Navigator.of(context).pop(url),
                      child: AppNetworkImage(url: url, borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onChanged([...photos, picked]);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final url in photos)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  AppNetworkImage(url: url, width: 120, height: 96, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: InkWell(
                      onTap: () => onChanged([...photos]..remove(url)),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (photos.length < max)
            InkWell(
              onTap: () => _add(context),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: tokens.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: tokens.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                    const SizedBox(height: 4),
                    Text(photos.isEmpty ? 'Add photos' : 'Add more', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
