import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'rating_stars.dart';

/// What the rider entered in the review sheet.
class ReviewDraft {
  final int rating;
  final bool worthIt;
  final String text;

  const ReviewDraft({required this.rating, required this.worthIt, required this.text});
}

/// Bottom sheet for "How was it?": stars, worth it or not, and a few words.
/// Returns null when dismissed.
Future<ReviewDraft?> showWriteReviewSheet(
  BuildContext context, {
  required String placeName,
  int initialRating = 0,
  bool? initialWorthIt,
}) {
  return showModalBottomSheet<ReviewDraft>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _WriteReviewSheet(
      placeName: placeName,
      initialRating: initialRating,
      initialWorthIt: initialWorthIt,
    ),
  );
}

class _WriteReviewSheet extends StatefulWidget {
  final String placeName;
  final int initialRating;
  final bool? initialWorthIt;

  const _WriteReviewSheet({required this.placeName, required this.initialRating, required this.initialWorthIt});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  late int _rating = widget.initialRating;
  late bool? _worthIt = widget.initialWorthIt;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _rating > 0 && _worthIt != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('How was ${widget.placeName}?', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spaceSm),
              RatingPicker(value: _rating, onChanged: (value) => setState(() => _rating = value)),
              const SizedBox(height: AppDimensions.spaceSm),
              Text('Was it worth going?', style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spaceXs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                    label: const Text('Worth it'),
                    selected: _worthIt == true,
                    selectedColor: AppColors.success.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _worthIt = true),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  ChoiceChip(
                    avatar: const Icon(Icons.thumb_down_alt_outlined, size: 18),
                    label: const Text('Not worth it'),
                    selected: _worthIt == false,
                    selectedColor: AppColors.error.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _worthIt = false),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppTextField(
                label: 'Your review (optional)',
                hint: 'Tips for the next visitor: road, crowds, best time…',
                controller: _textController,
                maxLines: 4,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppButton(
                label: 'Post review',
                onPressed: _canSubmit
                    ? () => Navigator.of(context).pop(
                          ReviewDraft(rating: _rating, worthIt: _worthIt!, text: _textController.text.trim()),
                        )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
