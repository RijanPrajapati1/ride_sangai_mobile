import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/ride_card.dart';
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

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is AppException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs a join/leave action with the loading state and error SnackBar.
  Future<bool> _runAction(Future<void> Function() action) async {
    setState(() => _actionLoading = true);
    try {
      await action();
      return true;
    } catch (error) {
      _showError(error);
      return false;
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _requestToJoin() async {
    final ok = await _runAction(() => ref.read(rideActionsControllerProvider).requestToJoin(widget.rideId));
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to the organizer!')),
      );
    }
  }

  Future<void> _cancelRequest() async {
    await _runAction(() => ref.read(rideActionsControllerProvider).cancelRequest(widget.rideId));
  }

  Future<void> _cancelRide(Ride ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this ride?'),
        content: const Text('Everyone who joined or asked to join will be notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep ride')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cancel ride')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _runAction(() => ref.read(rideActionsControllerProvider).cancelRide(ride.id));
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${ride.title}" was cancelled.')));
      context.pop();
    }
  }

  Future<void> _messageOrganizer(Ride ride) async {
    try {
      final conversation = await ref.read(messageActionsControllerProvider).openConversationWith(
            userId: ride.organizerId,
            userName: ride.organizerName,
            userAvatarUrl: ride.organizerAvatarUrl,
          );
      if (mounted) context.push(RouteNames.conversationPath(conversation.id));
    } catch (error) {
      _showError(error);
    }
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
        data: (ride) => _RideDetailsContent(
          ride: ride,
          onCancelRide: ride.isOrganizer && !ride.hasStarted ? () => _cancelRide(ride) : null,
          onEditRide: ride.isOrganizer && !ride.hasStarted ? () => context.push(RouteNames.editRidePath(ride.id)) : null,
        ),
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
  final VoidCallback? onCancelRide;
  final VoidCallback? onEditRide;

  const _RideDetailsContent({required this.ride, this.onCancelRide, this.onEditRide});

  Future<void> _openDirections(BuildContext context) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': ride.meetingPoint});
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps on this device')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.appColors;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 280,
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          // Icons sit in dark circles so they stay visible over a bright
          // photo and after the bar collapses onto the light background.
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: _GlassCircle(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          actions: [
            if (onCancelRide != null || onEditRide != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: _GlassCircle(
                  child: PopupMenuButton<String>(
                    iconColor: Colors.white,
                    tooltip: 'Ride options',
                    onSelected: (value) => value == 'edit' ? onEditRide?.call() : onCancelRide?.call(),
                    itemBuilder: (context) => [
                      if (onEditRide != null) const PopupMenuItem(value: 'edit', child: Text('Edit ride')),
                      if (onCancelRide != null) const PopupMenuItem(value: 'cancel', child: Text('Cancel ride')),
                    ],
                  ),
                ),
              ),
          ],
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
                      stops: [0, 0.3, 0.7, 1],
                      colors: [Colors.black26, Colors.transparent, Colors.transparent, Colors.black26],
                    ),
                  ),
                ),
                Positioned(
                  left: AppDimensions.spaceMd,
                  bottom: AppDimensions.spaceMd,
                  child: Row(
                    children: [
                      RideDifficultyBadge(difficulty: ride.difficulty),
                      const SizedBox(width: AppDimensions.spaceXs),
                      _TypeBadge(type: ride.rideType),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceMd,
              AppDimensions.spaceMd,
              AppDimensions.spaceMd,
              AppDimensions.spaceXl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride.title, style: theme.textTheme.displayLarge),
                const SizedBox(height: AppDimensions.spaceSm),
                InkWell(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  onTap: () => context.push(RouteNames.userProfilePath(ride.organizerId)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        AppAvatar(imageUrl: ride.organizerAvatarUrl, name: ride.organizerName, size: 40),
                        const SizedBox(width: AppDimensions.spaceSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ride.organizerName, style: theme.textTheme.titleMedium),
                              Text('Organizer · View profile', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: tokens.textMuted),
                      ],
                    ),
                  ),
                ),
                if (ride.joinStatus == RideJoinStatus.declined) ...[
                  const SizedBox(height: AppDimensions.spaceMd),
                  _DeclinedNotice(reason: ride.myRequest?.declineReason),
                ],
                const SizedBox(height: AppDimensions.spaceMd),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXs),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.event_rounded,
                          title: ride.date.toFullDate,
                          subtitle: 'Starts at ${ride.date.toTime}',
                        ),
                        Divider(indent: 68, color: tokens.divider),
                        _DetailRow(
                          icon: Icons.place_rounded,
                          title: ride.meetingPoint,
                          subtitle: 'Meeting point',
                          trailing: TextButton.icon(
                            onPressed: () => _openDirections(context),
                            icon: const Icon(Icons.directions_rounded, size: 18),
                            label: const Text('Directions'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.route_rounded,
                              label: '${ride.distanceKm.toStringAsFixed(0)} km',
                              caption: 'Distance',
                            ),
                          ),
                          VerticalDivider(color: tokens.divider),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.timer_outlined,
                              label: formatDuration(ride.durationMinutes),
                              caption: 'Duration',
                            ),
                          ),
                          VerticalDivider(color: tokens.divider),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.terrain_rounded,
                              label: ride.difficulty.label,
                              caption: 'Difficulty',
                              color: ride.difficulty.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                Text('About this ${ride.rideType.category.activitySingular.toLowerCase()}', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(ride.description, style: theme.textTheme.bodyLarge?.copyWith(color: tokens.textSecondary)),
                if (ride.requirements.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spaceLg),
                  Text('What to bring', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppDimensions.spaceSm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in ride.requirements) AppChip(label: item, icon: Icons.check_circle_outline_rounded),
                    ],
                  ),
                ],
                const SizedBox(height: AppDimensions.spaceLg),
                Text("Who's going", style: theme.textTheme.titleLarge),
                const SizedBox(height: AppDimensions.spaceSm),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push(RouteNames.rideParticipantsPath(ride.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spaceMd),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ParticipantAvatarsRow(
                                    avatarUrls: ride.participantAvatars,
                                    totalCount: ride.participantCount,
                                  ),
                                ),
                              ),
                              RideSpotsPill(ride: ride),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceSm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                            child: LinearProgressIndicator(
                              value: ride.maxParticipants == 0
                                  ? 0
                                  : (ride.participantCount / ride.maxParticipants).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: tokens.surfaceAlt,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceXs),
                          Row(
                            children: [
                              Text(
                                '${ride.participantCount} of ${ride.maxParticipants} going',
                                style: theme.textTheme.bodySmall,
                              ),
                              const Spacer(),
                              Text(
                                'See everyone',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeclinedNotice extends StatelessWidget {
  final String? reason;

  const _DeclinedNotice({this.reason});

  @override
  Widget build(BuildContext context) {
    final hasReason = reason != null && reason!.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        hasReason
            ? 'The organizer declined your request: "${reason!.trim()}". You can ask again.'
            : 'The organizer declined your request. You can ask again.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

/// Dark translucent circle behind an app-bar icon, so it reads on any photo.
class _GlassCircle extends StatelessWidget {
  final Widget child;

  const _GlassCircle({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: 40, height: 40, child: Center(child: child)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final RideType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            type.label,
            style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _DetailRow({required this.icon, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd, vertical: AppDimensions.spaceXs),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final Color color;

  const _StatTile({required this.icon, required this.label, required this.caption, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
