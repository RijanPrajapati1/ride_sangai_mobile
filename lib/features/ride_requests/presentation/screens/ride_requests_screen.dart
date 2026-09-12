import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/ride_request.dart';
import '../providers/ride_request_providers.dart';
import '../widgets/decline_reason_dialog.dart';
import '../widgets/ride_request_tile.dart';

class RideRequestsScreen extends ConsumerWidget {
  final String rideId;

  const RideRequestsScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ride Requests'),
          bottom: const TabBar(tabs: [Tab(text: 'Pending'), Tab(text: 'Approved'), Tab(text: 'Declined')]),
        ),
        body: TabBarView(
          children: [
            _RequestsList(status: RideRequestStatus.pending, rideId: rideId),
            _RequestsList(status: RideRequestStatus.approved, rideId: rideId),
            _RequestsList(status: RideRequestStatus.declined, rideId: rideId),
          ],
        ),
      ),
    );
  }
}

class _RequestsList extends ConsumerWidget {
  final RideRequestStatus status;
  final String rideId;

  const _RequestsList({required this.status, required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(organizerRequestsProvider);
    final actions = ref.read(rideRequestActionsControllerProvider);

    return requestsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(organizerRequestsProvider)),
      data: (requests) {
        final filtered = requests.where((r) => r.status == status).toList();
        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No ${status.label.toLowerCase()} requests',
            message: 'Requests to join your rides will show up here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
          itemBuilder: (context, index) {
            final RideRequest request = filtered[index];
            return RideRequestTile(
              request: request,
              onApprove: () => actions.approve(request.id, rideId: rideId),
              onDecline: () async {
                final reason = await showDeclineReasonDialog(context, riderName: request.userName);
                if (reason == null) return;
                await actions.decline(
                  request.id,
                  rideId: rideId,
                  reason: reason.isEmpty ? null : reason,
                );
              },
            );
          },
        );
      },
    );
  }
}
