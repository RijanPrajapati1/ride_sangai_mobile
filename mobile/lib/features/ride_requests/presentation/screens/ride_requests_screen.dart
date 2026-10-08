import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/ride_request.dart';
import '../providers/ride_request_providers.dart';
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

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (error) {
      final message = error is AppException ? error.message : 'Something went wrong. Please try again.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _decline(BuildContext context, WidgetRef ref, RideRequest request) async {
    final reason = await showDialog<String>(context: context, builder: (_) => const _DeclineDialog());
    if (reason == null || !context.mounted) return;
    await _run(
      context,
      () => ref.read(rideRequestActionsControllerProvider).decline(request.id, rideId: rideId, reason: reason),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(rideRequestsForRideProvider(rideId));

    return requestsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, st) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(rideRequestsForRideProvider(rideId)),
      ),
      data: (requests) {
        final filtered = requests.where((r) => r.status == status).toList();
        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No ${status.label.toLowerCase()} requests',
            message: 'Requests to join your rides will show up here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(rideRequestsForRideProvider(rideId).future),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
            itemBuilder: (context, index) {
              final RideRequest request = filtered[index];
              return RideRequestTile(
                request: request,
                onViewProfile: () => context.push(RouteNames.userProfilePath(request.userId)),
                onApprove: () => _run(
                  context,
                  () => ref.read(rideRequestActionsControllerProvider).approve(request.id, rideId: rideId),
                ),
                onDecline: () => _decline(context, ref, request),
              );
            },
          ),
        );
      },
    );
  }
}

/// Asks for an optional reason (shared with the rider). Pops the reason ('' for
/// none) or null when cancelled.
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decline request?'),
      content: TextField(
        controller: _controller,
        maxLength: 500,
        maxLines: 3,
        minLines: 1,
        decoration: const InputDecoration(hintText: 'Reason (optional, shared with the rider)'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop(_controller.text.trim()), child: const Text('Decline')),
      ],
    );
  }
}
