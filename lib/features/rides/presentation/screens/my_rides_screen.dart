import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/dashboard_category_provider.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/ride_card.dart';
import '../../domain/entities/ride.dart';
import '../providers/ride_providers.dart';

class MyRidesScreen extends ConsumerWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(selectedDashboardCategoryProvider);
    final noun = category.activityNoun;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My $noun'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
              Tab(text: 'Organized'),
              Tab(text: 'Joined'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _UpcomingTab(),
            _RideListTab(provider: dashboardPastRidesProvider, emptyMessage: '$noun you complete will show up here.'),
            _RideListTab(provider: dashboardOrganizedRidesProvider, emptyMessage: '$noun you organize will show up here.'),
            _RideListTab(provider: dashboardJoinedRidesProvider, emptyMessage: '$noun you join will show up here.'),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTab extends ConsumerWidget {
  const _UpcomingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noun = ref.watch(selectedDashboardCategoryProvider).activityNoun;
    final organizedAsync = ref.watch(dashboardOrganizedRidesProvider);
    final joinedAsync = ref.watch(dashboardJoinedRidesProvider);

    if (organizedAsync.isLoading || joinedAsync.isLoading) return const LoadingWidget();
    if (organizedAsync.hasError) {
      return AppErrorWidget(message: organizedAsync.error.toString(), onRetry: () => ref.invalidate(organizedRidesProvider));
    }
    if (joinedAsync.hasError) {
      return AppErrorWidget(message: joinedAsync.error.toString(), onRetry: () => ref.invalidate(joinedRidesProvider));
    }

    final now = DateTime.now();
    final combined = <String, Ride>{};
    for (final ride in organizedAsync.value ?? const <Ride>[]) {
      if (ride.date.isAfter(now)) combined[ride.id] = ride;
    }
    for (final ride in joinedAsync.value ?? const <Ride>[]) {
      combined[ride.id] = ride;
    }
    final rides = combined.values.toList()..sort((a, b) => a.date.compareTo(b.date));

    return _RideList(rides: rides, emptyMessage: 'You have no upcoming ${noun.toLowerCase()} yet.');
  }
}

class _RideListTab extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<Ride>>> provider;
  final String emptyMessage;

  const _RideListTab({required this.provider, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(provider);
    return ridesAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(provider)),
      data: (rides) => _RideList(rides: rides, emptyMessage: emptyMessage),
    );
  }
}

class _RideList extends StatelessWidget {
  final List<Ride> rides;
  final String emptyMessage;

  const _RideList({required this.rides, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return EmptyState(icon: Icons.route_outlined, title: 'Nothing here yet', message: emptyMessage);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      itemCount: rides.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
      itemBuilder: (context, index) {
        final ride = rides[index];
        return RideCard(ride: ride, onTap: () => context.push(RouteNames.rideDetailsPath(ride.id)));
      },
    );
  }
}
