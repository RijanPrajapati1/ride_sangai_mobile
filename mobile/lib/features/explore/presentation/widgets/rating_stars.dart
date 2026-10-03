import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Read-only star rating (supports half stars), e.g. 4.5 → ★★★★½.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: AppColors.warning,
          ),
      ],
    );
  }
}

/// Tappable 1–5 star picker for writing a review.
class RatingPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const RatingPicker({super.key, required this.value, required this.onChanged, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i star${i == 1 ? '' : 's'}',
            onPressed: () => onChanged(i),
            icon: Icon(
              value >= i ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: AppColors.warning,
            ),
          ),
      ],
    );
  }
}
