import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../utils/error_message.dart';

/// Picks photos from the gallery (up to [max] in total), uploads them
/// (`POST /uploads`, purpose `place`) and reports the full list of URLs.
class PlacePhotoPicker extends ConsumerStatefulWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onChanged;
  final int max;

  const PlacePhotoPicker({super.key, required this.photos, required this.onChanged, this.max = 5});

  @override
  ConsumerState<PlacePhotoPicker> createState() => _PlacePhotoPickerState();
}

class _PlacePhotoPickerState extends ConsumerState<PlacePhotoPicker> {
  bool _uploading = false;

  Future<void> _add() async {
    final remainingSlots = widget.max - widget.photos.length;
    if (remainingSlots < 1 || _uploading) return;
    setState(() => _uploading = true);
    try {
      final urls = await ref
          .read(uploadServiceProvider)
          .pickAndUploadMany(purpose: UploadPurpose.place, limit: remainingSlots);
      if (urls.isNotEmpty) widget.onChanged([...widget.photos, ...urls.take(remainingSlots)]);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    final photos = widget.photos;
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
                      onTap: _uploading ? null : () => widget.onChanged([...photos]..remove(url)),
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
          if (photos.length < widget.max || _uploading)
            InkWell(
              onTap: _uploading ? null : _add,
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
                    if (_uploading)
                      const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    else
                      const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                    const SizedBox(height: 4),
                    Text(
                      _uploading ? 'Uploading…' : (photos.isEmpty ? 'Add photos' : 'Add more'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
