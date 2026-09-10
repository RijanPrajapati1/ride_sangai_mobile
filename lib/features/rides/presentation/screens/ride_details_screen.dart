import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../messages/presentation/providers/message_providers.dart';
import '../../domain/entities/ride.dart';
import '../providers/ride_providers.dart';
import '../widgets/participant_avatars_row.dart';
import '../widgets/ride_join_action_bar.dart';

class RideDetailsScreen extends ConsumerStatefulWidget {
  final String rideId;

  const RideDetailsScreen({super.key, required this.rideId});

  @override
  ConsumerState<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends ConsumerState<RideDetailsScreen> {
  bool _actionLoading = false;

  Future<void> _requestToJoin() async {
    setState(() => _actionLoading = true);
    await ref.read(rideActionsControllerProvider).requestToJoin(widget.rideId);
    if (mounted) {
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to the organizer!')),
      );
    }
  }

  Future<void> _cancelRequest() async {
    setState(() => _actionLoading = true);
    await ref.read(rideActionsControllerProvider).cancelRequest(widget.rideId);
    if (mounted) setState(() => _actionLoading = false);
  }

  Future<void> _messageOrganizer(Ride ride) async {
    final conversation = await ref.read(messageActionsControllerProvider).openConversationWith(
          userId: ride.organizerId,
          userName: ride.organizerName,
          userAvatarUrl: ride.organizerAvatarUrl,
        );
    if (mounted) context.push(RouteNames.conversationPath(conversation.id));
  }

  @override
  Widget build(BuildContext context) {
    final rideAsync = ref.watch(rideDetailsProvider(widget.rideId));

    return Scaffold(
      body: rideAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(rideDetailsProvider(widget.rideId)),
        ),
        data: (ride) => _RideDetailsContent(ride: ride),
      ),
      bottomNavigationBar: rideAsync.maybeWhen(
        data: (ride) => RideJoinActionBar(
          ride: ride,
          isLoading: _actionLoading,
          onRequestToJoin: _requestToJoin,
          onCancelRequest: _cancelRequest,
          onManageRequests: () => context.push(RouteNames.rideRequestsPath(ride.id)),
          onMessageOrganizer: () => _messageOrganizer(ride),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _RideDetailsContent extends StatelessWidget {
  final Ride ride;

  const _RideDetailsContent({required this.ride});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 240,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(url: ride.imageUrl, fallbackIcon: ride.rideType.icon),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black38],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    AppChip(label: ride.difficulty.label, color: ride.difficulty.color, selected: true),
                    AppChip(label: ride.rideType.label, icon: ride.rideType.icon),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Text(ride.title, style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: AppDimensions.spaceMd),
                InkWell(
                  onTap: () => context.push(RouteNames.userProfilePath(ride.organizerId)),
                  child: Row(
                    children: [
                      AppAvatar(imageUrl: ride.organizerAvatarUrl, name: ride.organizerName, size: 40),
                      const SizedBox(width: AppDimensions.spaceSm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ride.organizerName, style: Theme.of(context).textTheme.titleMedium),
                          Text('Ride organizer', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                _InfoRow(icon: Icons.calendar_today_outlined, label: ride.date.toFullDate),
                _InfoRow(icon: Icons.access_time, label: ride.date.toTime),
                _InfoRow(icon: Icons.location_on_outlined, label: ride.meetingPoint),
                const SizedBox(height: AppDimensions.spaceSm),
                _MapPlaceholder(location: ride.meetingPoint),
                const SizedBox(height: AppDimensions.spaceLg),
                Row(
                  children: [
                    Expanded(child: _StatTile(icon: Icons.route_outlined, label: '${ride.distanceKm.toStringAsFixed(0)} km', caption: 'Distance')),
                    Expanded(child: _StatTile(icon: Icons.timer_outlined, label: _formatDuration(ride.durationMinutes), caption: 'Duration')),
                    Expanded(child: _StatTile(icon: Icons.terrain_outlined, label: ride.difficulty.label, caption: 'Difficulty')),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                Text('About this ride', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(ride.description, style: Theme.of(context).textTheme.bodyLarge),
                if (ride.requirements.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spaceLg),
                  Text('What to bring', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppDimensions.spaceSm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final item in ride.requirements) AppChip(label: item, icon: Icons.check)],
                  ),
                ],
                const SizedBox(height: AppDimensions.spaceLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Participants', style: Theme.of(context).textTheme.titleLarge),
                    ParticipantAvatarsRow(
                      avatarUrls: ride.participantAvatars,
                      totalCount: ride.participantCount,
                      onTap: () => context.push(RouteNames.rideParticipantsPath(ride.id)),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceXxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final String location;

  const _MapPlaceholder({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, color: AppColors.textMuted, size: 28),
          const SizedBox(height: 6),
          Text('Map preview coming soon', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;

  const _StatTile({required this.icon, required this.label, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
