import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/utils/geo.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../domain/entities/place.dart';
import 'rating_stars.dart';

/// Explore card: photo, category, name, where it is, how far, and how people rated it.
class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final VoidCallback? onToggleSave;

  /// Shorter image for horizontal carousels.
  final bool compact;

  const PlaceCard({super.key, required this.place, required this.onTap, this.onToggleSave, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  url: place.coverImageUrl,
                  height: compact ? 120 : 170,
                  width: double.infinity,
                  fallbackIcon: place.category.icon,
                ),
                Positioned(left: 10, top: 10, child: _CategoryBadge(category: place.category)),
                if (onToggleSave != null)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Material(
                      color: Colors.black38,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: place.isSaved ? 'Remove from saved' : 'Save',
                        onPressed: onToggleSave,
                        icon: Icon(place.isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: tokens.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      if (place.distanceKm != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          formatDistance(place.distanceKm!),
                          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  PlaceRatingLine(place: place),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "★★★★½ 4.5 (12) · 92% worth it", or "No reviews yet".
class PlaceRatingLine extends StatelessWidget {
  final Place place;

  const PlaceRatingLine({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (place.averageRating == null) {
      return Text('No reviews yet — be the first', style: theme.textTheme.bodySmall);
    }
    return Row(
      children: [
        RatingStars(rating: place.averageRating!, size: 14),
        const SizedBox(width: 4),
        Text(
          '${place.averageRating!.toStringAsFixed(1)} (${place.reviewCount})',
          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (place.worthItPercent != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '· ${place.worthItPercent}% worth it',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final PlaceCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
