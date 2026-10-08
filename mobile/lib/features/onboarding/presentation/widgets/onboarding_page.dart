import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/mountain_backdrop.dart';

class OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  /// Small sample cards floating on the illustration, hinting at what the
  /// feature looks like in use.
  final List<({IconData icon, String label})> highlights;

  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    this.highlights = const [],
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLg),
      child: Column(
        children: [
          Expanded(child: _Illustration(data: data)),
          const SizedBox(height: AppDimensions.spaceLg),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLg.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLg.copyWith(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final OnboardingPageData data;

  const _Illustration({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(colors: data.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: MountainBackdrop(height: 0.5)),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
              ),
              child: Icon(data.icon, size: 60, color: Colors.white),
            ),
          ),
          Positioned(
            left: AppDimensions.spaceMd,
            right: AppDimensions.spaceMd,
            bottom: AppDimensions.spaceMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, highlight) in data.highlights.indexed)
                  Padding(
                    padding: EdgeInsets.only(top: AppDimensions.spaceXs, left: i.isOdd ? AppDimensions.spaceXl : 0),
                    child: _HighlightPill(icon: highlight.icon, label: highlight.label, color: data.gradient.last),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HighlightPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.labelLg.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
