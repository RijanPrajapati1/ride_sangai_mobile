import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../shared/widgets/app_network_image.dart';

/// Cover-photo selector: picks a photo from the gallery, uploads it
/// (`POST /uploads`, purpose `rideCover`) and reports the uploaded URL.
class CoverImagePicker extends ConsumerStatefulWidget {
  final String? imageUrl;
  final ValueChanged<String> onChanged;

  const CoverImagePicker({super.key, required this.imageUrl, required this.onChanged});

  @override
  ConsumerState<CoverImagePicker> createState() => _CoverImagePickerState();
}

class _CoverImagePickerState extends ConsumerState<CoverImagePicker> {
  bool _uploading = false;

  Future<void> _pick() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final url = await ref.read(uploadServiceProvider).pickAndUpload(purpose: UploadPurpose.rideCover);
      if (url != null) widget.onChanged(url);
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException ? error.message : 'Could not upload the photo. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    final imageUrl = widget.imageUrl;
    return InkWell(
      onTap: _uploading ? null : _pick,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        height: 150,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: tokens.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl == null || imageUrl.isEmpty)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: tokens.textMuted, size: 30),
                  const SizedBox(height: 6),
                  Text('Add cover photo', style: Theme.of(context).textTheme.bodyMedium),
                ],
              )
            else ...[
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
            if (_uploading)
              const ColoredBox(
                color: Colors.black38,
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
