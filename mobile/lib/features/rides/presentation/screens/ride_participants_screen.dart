import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../shared/layouts/app_scaffold.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/user_tile.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../domain/entities/ride_participant.dart';
import '../providers/ride_providers.dart';

class RideParticipantsScreen extends ConsumerWidget {
  final String rideId;

  const RideParticipantsScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(rideParticipantsProvider(rideId));

    return AppScaffold(
      appBar: const AppAppBar(title: 'Participants'),
      body: participantsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(rideParticipantsProvider(rideId)),
        ),
        data: (all) {
          // Organizer, then approved riders, then pending requests.
          final participants = [
            for (final status in _order) ...all.where((p) => p.status == status),
          ];
          if (participants.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No participants yet',
              message: 'Riders who join will show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: participants.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final participant = participants[index];
              return UserTile(
                avatarUrl: participant.avatarUrl,
                name: participant.name,
                subtitle: _subtitle(participant),
                trailing: AppChip(
                  label: _statusLabel(participant.status),
                  color: _statusColor(participant.status),
                  selected: true,
                ),
                onTap: () => context.push(RouteNames.userProfilePath(participant.userId)),
              );
            },
          );
        },
      ),
    );
  }

  static const _order = [RideJoinStatus.organizer, RideJoinStatus.approved, RideJoinStatus.pending];

  static String _subtitle(RideParticipant participant) => switch (participant.status) {
        RideJoinStatus.organizer => 'Created ${participant.joinedAt.timeAgo}',
        RideJoinStatus.pending => 'Requested ${participant.joinedAt.timeAgo}',
        _ => 'Joined ${participant.joinedAt.timeAgo}',
      };

  static String _statusLabel(RideJoinStatus status) => switch (status) {
        RideJoinStatus.organizer => 'Organizer',
        RideJoinStatus.pending => 'Pending',
        RideJoinStatus.declined => 'Declined',
        _ => 'Approved',
      };

  static Color _statusColor(RideJoinStatus status) => switch (status) {
        RideJoinStatus.organizer => AppColors.primary,
        RideJoinStatus.pending => AppColors.warning,
        RideJoinStatus.declined => AppColors.error,
        _ => AppColors.success,
      };
}
