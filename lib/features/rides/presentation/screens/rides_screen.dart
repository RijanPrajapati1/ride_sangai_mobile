import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
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
    final filters = ref.watch(rideFiltersProvider);
    final ridesAsync = ref.watch(filteredRidesProvider);
    final filtersController = ref.read(rideFiltersProvider.notifier);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Rides'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create ride',
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
              decoration: const InputDecoration(
                hintText: 'Search rides or locations',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          RideFilterBar(
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
                    title: 'No rides found',
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
