import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/utils/geo.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/place.dart';
import '../providers/explore_providers.dart';
import '../widgets/place_map.dart';
import '../widgets/rating_stars.dart';
import '../widgets/review_tile.dart';
import '../widgets/write_review_sheet.dart';

class PlaceDetailsScreen extends ConsumerWidget {
  final String placeId;

  const PlaceDetailsScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeAsync = ref.watch(placeDetailsProvider(placeId));
    return Scaffold(
      body: placeAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => Scaffold(
          appBar: AppBar(),
          body: AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(placeDetailsProvider(placeId))),
        ),
        data: (place) => _PlaceDetailsContent(place: place),
      ),
    );
  }
}

class _PlaceDetailsContent extends ConsumerWidget {
  final Place place;

  const _PlaceDetailsContent({required this.place});

  Future<void> _openDirections(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps on this device')));
    }
  }

  Future<void> _writeReview(BuildContext context, WidgetRef ref) async {
    final draft = await showWriteReviewSheet(
      context,
      placeName: place.name,
      initialRating: place.myReview?.rating ?? 0,
      initialWorthIt: place.myReview?.worthIt,
    );
    if (draft == null) return;
    try {
      await ref.read(exploreActionsControllerProvider).submitReview(
            placeId: place.id,
            rating: draft.rating,
            worthIt: draft.worthIt,
            text: draft.text,
            visitedOn: DateTime.now(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks! Your review is up.')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteReview(BuildContext context, WidgetRef ref) async {
    await ref.read(exploreActionsControllerProvider).deleteReview(place.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your review was removed')));
    }
  }

  Future<void> _deletePlace(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${place.name}"?'),
        content: const Text('The place and its reviews will be removed for everyone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(exploreActionsControllerProvider).deletePlace(place.id);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.appColors;
    final reviewsAsync = ref.watch(placeReviewsProvider(place.id));
    final location = ref.watch(currentLocationProvider).value;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 260,
          backgroundColor: theme.scaffoldBackgroundColor,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              tooltip: place.isSaved ? 'Remove from saved' : 'Save',
              icon: Icon(place.isSaved ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () => ref.read(exploreActionsControllerProvider).toggleSave(place.id, isCurrentlySaved: place.isSaved),
            ),
            if (place.isMine)
              IconButton(
                tooltip: 'Delete place',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deletePlace(context, ref),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(background: _PhotoGallery(place: place)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppChip(label: place.category.label, icon: place.category.icon, color: place.category.color, selected: true),
                    for (final activity in place.activities) AppChip(label: activity.label, icon: activity.icon),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Text(place.name, style: theme.textTheme.displayLarge),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(place.locationName, style: theme.textTheme.bodyLarge)),
                    if (place.distanceKm != null)
                      Text(
                        '${formatDistance(place.distanceKm!)} away',
                        style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                _RatingSummary(place: place),
                const SizedBox(height: AppDimensions.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Directions',
                        icon: Icons.directions_outlined,
                        onPressed: () => _openDirections(context),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Expanded(
                      child: AppOutlinedButton(
                        label: place.isSaved ? 'Saved' : 'Want to go',
                        icon: place.isSaved ? Icons.bookmark : Icons.bookmark_add_outlined,
                        onPressed: () =>
                            ref.read(exploreActionsControllerProvider).toggleSave(place.id, isCurrentlySaved: place.isSaved),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                PlaceMapPreview(place: place, userLocation: location?.point, onTap: () => _openDirections(context)),
                const SizedBox(height: 4),
                Text(
                  '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                Text('About this place', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(place.description, style: theme.textTheme.bodyLarge),
                if (place.bestTime != null || place.entryFee != null) ...[
                  const SizedBox(height: AppDimensions.spaceMd),
                  if (place.bestTime != null) _InfoRow(icon: Icons.wb_sunny_outlined, title: 'Best time to go', value: place.bestTime!),
                  if (place.entryFee != null) _InfoRow(icon: Icons.confirmation_number_outlined, title: 'Entry', value: place.entryFee!),
                ],
                if (place.tips != null) ...[
                  const SizedBox(height: AppDimensions.spaceMd),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spaceSm),
                    decoration: BoxDecoration(
                      color: tokens.primaryLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Local tip: ${place.tips!}', style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.spaceLg),
                InkWell(
                  onTap: () => context.push(RouteNames.userProfilePath(place.authorId)),
                  child: Row(
                    children: [
                      AppAvatar(imageUrl: place.authorAvatarUrl, name: place.authorName, size: 40),
                      const SizedBox(width: AppDimensions.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.isMine ? 'Shared by you' : 'Shared by ${place.authorName}', style: theme.textTheme.titleMedium),
                            Text('${place.createdAt.timeAgo} · ${place.saveCount} want to go', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                Row(
                  children: [
                    Expanded(child: Text('Reviews', style: theme.textTheme.titleLarge)),
                    if (!place.isMine)
                      TextButton.icon(
                        onPressed: () => _writeReview(context, ref),
                        icon: Icon(place.myReview == null ? Icons.rate_review_outlined : Icons.edit_outlined, size: 18),
                        label: Text(place.myReview == null ? 'Write a review' : 'Edit your review'),
                      ),
                  ],
                ),
                if (place.myReview != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _deleteReview(context, ref),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Delete my review'),
                    ),
                  ),
                reviewsAsync.when(
                  loading: () => const SizedBox(height: 80, child: LoadingWidget()),
                  error: (e, st) => AppErrorWidget(message: e.toString()),
                  data: (reviews) {
                    if (reviews.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
                        child: Text(
                          place.isMine
                              ? 'No reviews yet. Riders who visit will tell others if it was worth it.'
                              : 'No reviews yet. Been here? Tell others if it was worth it.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final review in reviews) ...[
                          ReviewTile(
                            review: review,
                            onAuthorTap: () => context.push(RouteNames.userProfilePath(review.userId)),
                          ),
                          Divider(color: tokens.divider, height: 1),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spaceXxl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoGallery extends StatefulWidget {
  final Place place;

  const _PhotoGallery({required this.place});

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.place.photos;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photos.isEmpty)
          AppNetworkImage(url: null, fallbackIcon: widget.place.category.icon)
        else
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => AppNetworkImage(url: photos[index], fallbackIcon: widget.place.category.icon),
          ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black26, Colors.transparent, Colors.black38],
              ),
            ),
          ),
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < photos.length; i++)
                  Container(
                    width: i == _index ? 18 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _index ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final Place place;

  const _RatingSummary({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceSm),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: place.averageRating == null
          ? Row(
              children: [
                const Icon(Icons.star_outline_rounded, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(child: Text('No reviews yet', style: theme.textTheme.titleSmall)),
              ],
            )
          : Row(
              children: [
                Text(place.averageRating!.toStringAsFixed(1), style: theme.textTheme.displayMedium),
                const SizedBox(width: AppDimensions.spaceSm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingStars(rating: place.averageRating!, size: 18),
                    Text('${place.reviewCount} review${place.reviewCount == 1 ? '' : 's'}', style: theme.textTheme.bodySmall),
                  ],
                ),
                const Spacer(),
                if (place.worthItPercent != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${place.worthItPercent}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: place.worthItPercent! >= 50 ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text('say worth it', style: theme.textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$title: ', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  TextSpan(text: value, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
