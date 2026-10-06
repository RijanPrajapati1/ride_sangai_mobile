import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/community_post.dart';
import '../providers/community_providers.dart';

/// Opens the composer to share a new post, or to edit [post] when given.
/// Resolves to true when something was saved.
Future<bool?> showPostComposerSheet(BuildContext context, {CommunityPost? post}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PostComposerSheet(post: post),
  );
}

class PostComposerSheet extends ConsumerStatefulWidget {
  final CommunityPost? post;

  const PostComposerSheet({super.key, this.post});

  @override
  ConsumerState<PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends ConsumerState<PostComposerSheet> {
  static const _maxLength = 2000;

  late final _textController = TextEditingController(text: widget.post?.text ?? '');
  late String? _imageUrl = widget.post?.imageUrl;
  bool _uploading = false;
  bool _saving = false;

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    try {
      final url = await ref.read(uploadServiceProvider).pickAndUpload(purpose: UploadPurpose.post);
      if (url != null && mounted) setState(() => _imageUrl = url);
    } on AppException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _saving || _uploading) return;
    setState(() => _saving = true);
    final actions = ref.read(communityActionsControllerProvider);
    try {
      final original = widget.post;
      if (original == null) {
        await actions.createPost(text: text, imageUrl: _imageUrl);
      } else {
        await actions.updatePost(
          original.id,
          text: text == original.text ? null : text,
          imageUrl: _imageUrl == original.imageUrl ? null : _imageUrl,
          removeImage: _imageUrl == null && original.imageUrl != null,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      _showError(e.message);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _textController.text.trim().isNotEmpty && !_uploading;

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.spaceMd,
        right: AppDimensions.spaceMd,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimensions.spaceMd,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEditing ? 'Edit post' : 'New post', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppDimensions.spaceSm),
            TextField(
              controller: _textController,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              maxLength: _maxLength,
              decoration: const InputDecoration(hintText: 'Share a ride recap or update…'),
            ),
            if (_imageUrl != null) ...[
              Stack(
                children: [
                  AppNetworkImage(
                    url: _imageUrl,
                    height: 180,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filledTonal(
                      tooltip: 'Remove photo',
                      onPressed: _saving ? null : () => setState(() => _imageUrl = null),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSm),
            ],
            Row(
              children: [
                TextButton.icon(
                  onPressed: _uploading || _saving ? null : _pickImage,
                  icon: _uploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.photo_outlined),
                  label: Text(_imageUrl == null ? 'Add photo' : 'Change photo'),
                ),
                const Spacer(),
                AppButton(
                  label: _isEditing ? 'Save' : 'Post',
                  expand: false,
                  isLoading: _saving,
                  onPressed: canSubmit ? _submit : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
