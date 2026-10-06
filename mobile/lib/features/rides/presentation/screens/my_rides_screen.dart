import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/ride_card.dart';
import '../../domain/entities/ride.dart';
import '../providers/ride_providers.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Rides'),
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
            _RideListTab(provider: myUpcomingRidesProvider, emptyMessage: 'You have no upcoming rides yet.'),
            _RideListTab(provider: pastRidesProvider, emptyMessage: 'Rides you complete will show up here.'),
            _RideListTab(provider: organizedRidesProvider, emptyMessage: 'Rides you organize will show up here.'),
            _RideListTab(provider: joinedRidesProvider, emptyMessage: 'Rides you join will show up here.'),
          ],
        ),
      ),
    );
  }
}

class _RideListTab extends ConsumerWidget {
  final FutureProvider<List<Ride>> provider;
  final String emptyMessage;

  const _RideListTab({required this.provider, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(provider);
    return ridesAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(provider)),
      data: (rides) => RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: _RideList(rides: rides, emptyMessage: emptyMessage),
      ),
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
