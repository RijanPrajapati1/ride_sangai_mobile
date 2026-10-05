import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../shared/widgets/app_avatar.dart';

/// Profile-photo selector: opens the gallery, uploads the chosen photo and
/// reports its public URL through [onChanged]. The profile itself is only
/// saved when the form is.
class AvatarPicker extends ConsumerStatefulWidget {
  final String name;
  final String avatarUrl;
  final ValueChanged<String> onChanged;

  const AvatarPicker({super.key, required this.name, required this.avatarUrl, required this.onChanged});

  @override
  ConsumerState<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<AvatarPicker> {
  bool _isUploading = false;

  Future<void> _pick() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);
    try {
      final url = await ref.read(uploadServiceProvider).pickAndUpload(purpose: UploadPurpose.avatar);
      if (url != null) widget.onChanged(url);
    } catch (e) {
      if (!mounted) return;
      final message = e is AppException ? e.message : 'Could not upload the photo. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pick,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AppAvatar(imageUrl: widget.avatarUrl, name: widget.name, size: AppDimensions.avatarXl),
          if (_isUploading)
            Container(
              width: AppDimensions.avatarXl,
              height: AppDimensions.avatarXl,
              decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              ),
            ),
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
