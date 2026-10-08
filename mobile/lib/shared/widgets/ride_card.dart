import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_ext.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/enums/ride_enums.dart';
import '../../core/extensions/date_time_extensions.dart';
import '../../core/utils/duration_format.dart';
import '../../features/rides/domain/entities/ride.dart';
import 'app_avatar.dart';
import 'app_network_image.dart';

/// A ride in a list. [large] is the featured hero on Home (title over the
/// photo), [compact] fits a horizontal carousel, and the default is the
/// full-width list card.
class RideCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback? onTap;
  final bool large;
  final bool compact;

  const RideCard({super.key, required this.ride, this.onTap, this.large = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: large ? _buildLarge(context) : _buildStandard(context),
      ),
    );
  }

  Widget _buildLarge(BuildContext context) {
    const onImage = Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(url: ride.imageUrl, fallbackIcon: ride.rideType.icon),
              const _BottomScrim(),
              Positioned(top: 12, left: 12, child: RideDifficultyBadge(difficulty: ride.difficulty)),
              if (_status(ride) case final status?) Positioned(top: 12, right: 12, child: _StatusBadge(status: status)),
              Positioned(
                left: AppDimensions.spaceMd,
                right: AppDimensions.spaceMd,
                bottom: AppDimensions.spaceMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd.copyWith(color: onImage, height: 1.15),
                    ),
                    const SizedBox(height: 6),
                    _MetaLine(
                      icon: Icons.schedule_rounded,
                      label: '${ride.date.relativeDayLabel} · ${ride.date.toTime}',
                      color: onImage,
                    ),
                    const SizedBox(height: 2),
                    _MetaLine(icon: Icons.place_outlined, label: ride.meetingPoint, color: onImage),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spaceMd,
            AppDimensions.spaceSm,
            AppDimensions.spaceMd,
            AppDimensions.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(child: _Organizer(ride: ride)),
              _RideStats(ride: ride),
              const SizedBox(width: AppDimensions.spaceSm),
              RideSpotsPill(ride: ride),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandard(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.appColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: compact ? 120 : 150,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(url: ride.imageUrl, fallbackIcon: ride.rideType.icon),
              Positioned(top: 10, left: 10, child: RideDifficultyBadge(difficulty: ride.difficulty)),
              if (_status(ride) case final status?) Positioned(top: 10, right: 10, child: _StatusBadge(status: status)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(compact ? AppDimensions.spaceSm : AppDimensions.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ride.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              _MetaLine(
                icon: Icons.schedule_rounded,
                label: '${ride.date.relativeDayLabel} · ${ride.date.toTime}',
                color: muted,
              ),
              const SizedBox(height: 3),
              _MetaLine(icon: Icons.place_outlined, label: ride.meetingPoint, color: muted),
              SizedBox(height: compact ? AppDimensions.spaceSm : AppDimensions.spaceSm + 2),
              if (compact)
                Row(
                  children: [
                    Expanded(child: _RideStats(ride: ride)),
                    RideSpotsPill(ride: ride),
                  ],
                )
              else ...[
                Row(
                  children: [
                    Expanded(child: _Organizer(ride: ride)),
                    _RideStats(ride: ride),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                _SpotsBar(ride: ride),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// What the current rider has to do with this ride, if anything.
_RideStatus? _status(Ride ride) => switch (ride.joinStatus) {
      RideJoinStatus.organizer => const _RideStatus('Organizing', Icons.star_rounded, AppColors.primary),
      RideJoinStatus.approved => const _RideStatus('Joined', Icons.check_circle_rounded, AppColors.successDark),
      RideJoinStatus.pending => const _RideStatus('Requested', Icons.hourglass_top_rounded, AppColors.warningDark),
      RideJoinStatus.declined => const _RideStatus('Declined', Icons.block_rounded, AppColors.errorDark),
      RideJoinStatus.none => ride.isInProgress
          ? const _RideStatus('In progress', Icons.directions_bike_rounded, Colors.black87)
          : null,
    };

class _RideStatus {
  final String label;
  final IconData icon;
  final Color color;

  const _RideStatus(this.label, this.icon, this.color);
}

class _StatusBadge extends StatelessWidget {
  final _RideStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(status.label, style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Solid light pill with a colored dot, readable on any photo.
class RideDifficultyBadge extends StatelessWidget {
  final RideDifficulty difficulty;

  const RideDifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: difficulty.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            difficulty.label,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// "4 spots left", "2 spots left" (amber, filling up) or "Full".
class RideSpotsPill extends StatelessWidget {
  final Ride ride;

  const RideSpotsPill({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _spots(ride, isDark: Theme.of(context).brightness == Brightness.dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Text(label, style: AppTextStyles.labelSm.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

(String, Color) _spots(Ride ride, {required bool isDark}) {
  final left = math.max(0, ride.maxParticipants - ride.participantCount);
  if (ride.isFull) return ('Full', isDark ? AppColors.error : AppColors.errorDark);
  if (left <= 3) return ('$left spot${left == 1 ? '' : 's'} left', isDark ? AppColors.warning : AppColors.warningDark);
  return ('$left spots left', isDark ? AppColors.success : AppColors.successDark);
}

/// How full the ride is: "11 of 15 going" over a thin bar.
class _SpotsBar extends StatelessWidget {
  final Ride ride;

  const _SpotsBar({required this.ride});

  @override
  Widget build(BuildContext context) {
    final tokens = context.appColors;
    final (label, color) = _spots(ride, isDark: Theme.of(context).brightness == Brightness.dark);
    final fill = ride.maxParticipants == 0 ? 0.0 : (ride.participantCount / ride.maxParticipants).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Text(
              '${ride.participantCount} of ${ride.maxParticipants} going',
              style: AppTextStyles.labelSm.copyWith(color: tokens.textSecondary),
            ),
            const Spacer(),
            Text(label, style: AppTextStyles.labelSm.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 5,
            color: color,
            backgroundColor: tokens.surfaceAlt,
          ),
        ),
      ],
    );
  }
}

class _Organizer extends StatelessWidget {
  final Ride ride;

  const _Organizer({required this.ride});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppAvatar(imageUrl: ride.organizerAvatarUrl, name: ride.organizerName, size: 24),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            ride.organizerName,
            style: AppTextStyles.labelSm.copyWith(color: context.appColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// "34 km · 3h 30m".
class _RideStats extends StatelessWidget {
  final Ride ride;

  const _RideStats({required this.ride});

  @override
  Widget build(BuildContext context) {
    final muted = context.appColors.textSecondary;
    final style = AppTextStyles.labelSm.copyWith(color: muted);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.route_rounded, size: 14, color: muted),
        const SizedBox(width: 3),
        Text('${ride.distanceKm.toStringAsFixed(0)} km', style: style),
        const SizedBox(width: 8),
        Icon(Icons.timer_outlined, size: 14, color: muted),
        const SizedBox(width: 3),
        Text(formatDuration(ride.durationMinutes), style: style),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaLine({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color.withValues(alpha: 0.85)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(color: color, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// Darkens the bottom of a photo so white text on it stays legible.
class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.35, 1],
          colors: [Colors.transparent, AppColors.scrim],
        ),
      ),
    );
  }
}
