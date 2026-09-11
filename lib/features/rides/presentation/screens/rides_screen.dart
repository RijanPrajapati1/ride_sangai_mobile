import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/dashboard_category_provider.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../shared/layouts/app_scaffold.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/ride_card.dart';
import '../providers/ride_providers.dart';
import '../widgets/ride_filter_bar.dart';

class RidesScreen extends ConsumerWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(selectedDashboardCategoryProvider);
    final filters = ref.watch(rideFiltersProvider);
    final ridesAsync = ref.watch(filteredRidesProvider);
    final filtersController = ref.read(rideFiltersProvider.notifier);

    // A type filter from a previous category no longer applies once the
    // dashboard switches — drop it so the list isn't silently empty.
    ref.listen(selectedDashboardCategoryProvider, (previous, next) {
      if (previous != null && previous != next) filtersController.setType(null);
    });

    return AppScaffold(
      appBar: AppBar(
        title: Text(category.activityNoun),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create ${category.activitySingular.toLowerCase()}',
            onPressed: () => context.push(RouteNames.createRide),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceMd,
              AppDimensions.spaceSm,
              AppDimensions.spaceMd,
              AppDimensions.spaceSm,
            ),
            child: TextField(
              onChanged: filtersController.setQuery,
              decoration: InputDecoration(
                hintText: 'Search ${category.activityNoun.toLowerCase()} or locations',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          RideFilterBar(
            category: category,
            filters: filters,
            onTypeChanged: filtersController.setType,
            onDifficultyChanged: filtersController.setDifficulty,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Expanded(
            child: ridesAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(upcomingRidesProvider)),
              data: (rides) {
                if (rides.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: 'No ${category.activityNoun.toLowerCase()} found',
                    message: 'Try adjusting your search or filters.',
                    actionLabel: filters.isActive ? 'Clear filters' : null,
                    onAction: filters.isActive ? filtersController.clear : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(upcomingRidesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.spaceMd,
                      0,
                      AppDimensions.spaceMd,
                      AppDimensions.spaceXl,
                    ),
                    itemCount: rides.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
                    itemBuilder: (context, index) {
                      final ride = rides[index];
                      return RideCard(
                        ride: ride,
                        onTap: () => context.push(RouteNames.rideDetailsPath(ride.id)),
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
