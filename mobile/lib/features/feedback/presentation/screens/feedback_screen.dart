import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/platform_name.dart';
import '../../../../shared/utils/run_or_show_error.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../data/dto/feedback_dto.dart';
import '../../domain/entities/user_feedback.dart';
import '../providers/feedback_providers.dart';

/// Lets a rider send a bug report, idea or kind word to the team.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  FeedbackCategory _category = FeedbackCategory.idea;
  int? _rating;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  static String? validateMessage(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please write a message';
    if (text.length > SendFeedbackDto.maxMessageLength) {
      return 'Keep it under ${SendFeedbackDto.maxMessageLength} characters';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await runOrShowError(
      context,
      () => ref.read(feedbackControllerProvider.notifier).send(
            message: _messageController.text,
            category: _category,
            rating: _rating,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedbackControllerProvider);
    final sent = state.valueOrNull;

    return Scaffold(
      appBar: const AppAppBar(title: 'Send Feedback'),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: sent != null
              ? _SentView(key: const ValueKey('sent'), onDone: () => Navigator.of(context).maybePop())
              : _buildForm(context, isSending: state.isLoading),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool isSending}) {
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.appColors;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: [
          Text(
            'Tell us what is working and what is not. Every message goes straight to the ${AppConstants.appName} team.',
            style: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Text('What is it about?', style: textTheme.labelLarge),
          const SizedBox(height: AppDimensions.spaceXs),
          Wrap(
            spacing: AppDimensions.spaceXs,
            runSpacing: AppDimensions.spaceXs,
            children: [
              for (final category in FeedbackCategory.values)
                AppChip(
                  label: category.label,
                  icon: _categoryIcon(category),
                  selected: _category == category,
                  onTap: isSending ? null : () => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Row(
            children: [
              Text('How are we doing?', style: textTheme.labelLarge),
              const SizedBox(width: AppDimensions.spaceXs),
              Text('Optional', style: textTheme.bodySmall?.copyWith(color: tokens.textMuted)),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXxs),
          _StarRating(
            rating: _rating,
            enabled: !isSending,
            // Tapping the current rating again clears it.
            onChanged: (value) => setState(() => _rating = value == _rating ? null : value),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text('Message', style: textTheme.labelLarge),
          const SizedBox(height: AppDimensions.spaceXs),
          TextFormField(
            key: const ValueKey('feedback-message'),
            controller: _messageController,
            enabled: !isSending,
            minLines: 5,
            maxLines: 10,
            maxLength: SendFeedbackDto.maxMessageLength,
            // Let the counter turn red instead of silently cutting the text;
            // the validator explains the limit.
            maxLengthEnforcement: MaxLengthEnforcement.none,
            textCapitalization: TextCapitalization.sentences,
            validator: validateMessage,
            decoration: InputDecoration(hintText: _hintFor(_category), alignLabelWithHint: true),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Row(
            children: [
              Icon(Icons.info_outline, size: AppDimensions.iconSm, color: tokens.textMuted),
              const SizedBox(width: AppDimensions.spaceXxs),
              Expanded(
                child: Text(
                  'Sent with your account, device type (${currentPlatformName()}) and app version ${AppConstants.appVersion}.',
                  style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          AppButton(label: 'Send Feedback', icon: Icons.send_outlined, onPressed: _submit, isLoading: isSending),
        ],
      ),
    );
  }

  static IconData _categoryIcon(FeedbackCategory category) => switch (category) {
        FeedbackCategory.bug => Icons.bug_report_outlined,
        FeedbackCategory.idea => Icons.lightbulb_outline,
        FeedbackCategory.praise => Icons.favorite_border,
        FeedbackCategory.other => Icons.chat_bubble_outline,
      };

  static String _hintFor(FeedbackCategory category) => switch (category) {
        FeedbackCategory.bug => 'What happened, and what did you expect instead?',
        FeedbackCategory.idea => 'What would make your rides better?',
        FeedbackCategory.praise => 'What do you enjoy most?',
        FeedbackCategory.other => 'What is on your mind?',
      };
}

class _StarRating extends StatelessWidget {
  final int? rating;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _StarRating({required this.rating, required this.enabled, required this.onChanged});

  static const _labels = ['Poor', 'Fair', 'Good', 'Great', 'Excellent'];

  @override
  Widget build(BuildContext context) {
    final current = rating ?? 0;
    return Row(
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            key: ValueKey('feedback-star-$star'),
            tooltip: '$star star${star == 1 ? '' : 's'}',
            visualDensity: VisualDensity.compact,
            onPressed: enabled ? () => onChanged(star) : null,
            icon: Icon(
              star <= current ? Icons.star_rounded : Icons.star_outline_rounded,
              size: AppDimensions.iconLg,
              color: star <= current ? AppColors.warning : context.appColors.textMuted,
            ),
          ),
        const SizedBox(width: AppDimensions.spaceXs),
        if (rating != null)
          Text(
            _labels[current - 1],
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.warning),
          ),
      ],
    );
  }
}

class _SentView extends StatelessWidget {
  final VoidCallback onDone;

  const _SentView({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: context.appColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            Text('Thanks for your feedback!', style: textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              'The team reads every message. It helps us make ${AppConstants.appName} better for every rider.',
              style: textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceXl),
            AppButton(label: 'Done', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
