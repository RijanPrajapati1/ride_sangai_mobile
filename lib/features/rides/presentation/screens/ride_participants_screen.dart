import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../shared/layouts/app_scaffold.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/user_tile.dart';
import '../../../../core/extensions/date_time_extensions.dart';
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
        data: (participants) {
          if (participants.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No participants yet',
              message: 'Approved riders will show up here.',
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
                subtitle: 'Joined ${participant.joinedAt.timeAgo}',
                onTap: () => context.push(RouteNames.userProfilePath(participant.userId)),
              );
            },
          );
        },
      ),
    );
  }
}
