import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/dashboard_category_provider.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/place_category.dart';
import '../../../../core/location/location_service.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../providers/explore_providers.dart';
import '../widgets/place_card.dart';
import '../widgets/place_map.dart';

const _radiusOptions = <double?>[5, 10, 25, 50, 100, null];

String _radiusLabel(double? km) => km == null ? 'Any distance' : 'Within ${km.round()} km';

/// Explore: hidden gems and local favourites shared by riders, nearest first.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  bool _showMap = false;
  Place? _selectedOnMap;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(exploreFiltersProvider).query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _update(ExploreFilters Function(ExploreFilters) change) {
    final notifier = ref.read(exploreFiltersProvider.notifier);
    notifier.state = change(notifier.state);
  }

  Future<void> _toggleSave(Place place) async {
    await ref.read(exploreActionsControllerProvider).toggleSave(place.id, isCurrentlySaved: place.isSaved);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(place.isSaved ? 'Removed from saved places' : 'Saved "${place.name}" for later')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(exploreFiltersProvider);
    final placesAsync = ref.watch(explorePlacesProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    final category = ref.watch(selectedDashboardCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            tooltip: _showMap ? 'List view' : 'Map view',
            icon: Icon(_showMap ? Icons.view_list_outlined : Icons.map_outlined),
            onPressed: () => setState(() {
              _showMap = !_showMap;
              _selectedOnMap = null;
            }),
          ),
          IconButton(
            tooltip: 'Saved places',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => context.push(RouteNames.savedPlaces),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.sharePlace),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Share a place'),
      ),
      body: Column(
        children: [
          _LocationBanner(
            location: locationAsync.value,
            onRefresh: () => ref.invalidate(currentLocationProvider),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.spaceMd, AppDimensions.spaceXs, AppDimensions.spaceMd, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search places or areas',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filters.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _update((f) => f.copyWith(query: ''));
                        },
                      ),
              ),
              onSubmitted: (value) => _update((f) => f.copyWith(query: value.trim())),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
              children: [
                _SortMenu(value: filters.sort, onChanged: (sort) => _update((f) => f.copyWith(sort: sort))),
                const SizedBox(width: 8),
                if (filters.sort == PlaceSort.nearest) ...[
                  _RadiusMenu(
                    value: filters.radiusKm,
                    onChanged: (km) => _update((f) => km == null ? f.copyWith(clearRadius: true) : f.copyWith(radiusKm: km)),
                  ),
                  const SizedBox(width: 8),
                ],
                FilterChip(
                  avatar: Icon(category.icon, size: 16),
                  label: Text('Good for ${category.activityNoun.toLowerCase()}'),
                  selected: filters.matchDashboard,
                  onSelected: (value) => _update((f) => f.copyWith(matchDashboard: value)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
              children: [
                AppChip(
                  label: 'All',
                  selected: filters.category == null,
                  onTap: () => _update((f) => f.copyWith(clearCategory: true)),
                ),
                for (final c in PlaceCategory.values) ...[
                  const SizedBox(width: 8),
                  AppChip(
                    label: c.label,
                    icon: c.icon,
                    selected: filters.category == c,
                    onTap: () => _update((f) => filters.category == c ? f.copyWith(clearCategory: true) : f.copyWith(category: c)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Expanded(
            child: placesAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(explorePlacesProvider)),
              data: (places) {
                if (places.isEmpty) {
                  return EmptyState(
                    icon: Icons.travel_explore,
                    title: 'No places found',
                    message: filters.isActive || filters.radiusKm != null
                        ? 'Try a bigger radius, another category, or clear your search.'
                        : 'Know a hidden gem? Be the first to share it.',
                    actionLabel: 'Share a place',
                    onAction: () => context.push(RouteNames.sharePlace),
                  );
                }
                if (_showMap) {
                  final location = locationAsync.value ?? LocationService.fallback;
                  return Stack(
                    children: [
                      PlaceMap(
                        places: places,
                        center: location.point,
                        zoom: 10,
                        userLocation: location.point,
                        onPlaceTap: (place) => setState(() => _selectedOnMap = place),
                        onMapTap: (_) => setState(() => _selectedOnMap = null),
                      ),
                      if (_selectedOnMap != null)
                        Positioned(
                          left: AppDimensions.spaceMd,
                          right: AppDimensions.spaceMd,
                          bottom: 88,
                          child: SizedBox(
                            height: 240,
                            child: PlaceCard(
                              place: _selectedOnMap!,
                              compact: true,
                              onTap: () => context.push(RouteNames.placeDetailsPath(_selectedOnMap!.id)),
                            ),
                          ),
                        ),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(currentLocationProvider);
                    ref.invalidate(explorePlacesProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppDimensions.spaceMd, AppDimensions.spaceXs, AppDimensions.spaceMd, 96),
                    itemCount: places.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return PlaceCard(
                        place: place,
                        onTap: () => context.push(RouteNames.placeDetailsPath(place.id)),
                        onToggleSave: () => _toggleSave(place),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  final UserLocation? location;
  final VoidCallback onRefresh;

  const _LocationBanner({required this.location, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    final approximate = location?.isApproximate ?? true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd, vertical: 6),
      color: approximate ? tokens.secondaryLight : tokens.primaryLight,
      child: Row(
        children: [
          Icon(approximate ? Icons.location_searching : Icons.my_location, size: 16, color: approximate ? AppColors.secondary : AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              location == null
                  ? 'Finding your location…'
                  : approximate
                      ? 'Showing places around ${location!.label}. Turn on location for distances from you.'
                      : 'Showing places near you',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final PlaceSort value;
  final ValueChanged<PlaceSort> onChanged;

  const _SortMenu({required this.value, required this.onChanged});

  static String label(PlaceSort sort) => switch (sort) {
        PlaceSort.nearest => 'Nearest',
        PlaceSort.topRated => 'Top rated',
        PlaceSort.newest => 'Newest',
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PlaceSort>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final sort in PlaceSort.values) PopupMenuItem(value: sort, child: Text(label(sort))),
      ],
      child: Chip(
        avatar: const Icon(Icons.sort, size: 16),
        label: Text(label(value)),
      ),
    );
  }
}

class _RadiusMenu extends StatelessWidget {
  final double? value;
  final ValueChanged<double?> onChanged;

  const _RadiusMenu({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double?>(
      initialValue: value,
      // PopupMenuButton cannot report a null selection, so "Any" uses -1.
      onSelected: (km) => onChanged(km == -1 ? null : km),
      itemBuilder: (context) => [
        for (final km in _radiusOptions) PopupMenuItem(value: km ?? -1, child: Text(_radiusLabel(km))),
      ],
      child: Chip(
        avatar: const Icon(Icons.radar, size: 16),
        label: Text(_radiusLabel(value)),
      ),
    );
  }
}
