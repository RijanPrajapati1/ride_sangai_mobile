import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../groups/domain/entities/group.dart';
import '../../../ride_requests/domain/entities/ride_request.dart';
import '../../../ride_requests/presentation/widgets/decline_reason_dialog.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_group_row.dart';
import '../widgets/admin_post_row.dart';
import '../widgets/admin_ride_row.dart';
import '../widgets/admin_user_row.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<bool> _confirm(BuildContext context, {required String title, required String message}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminAllUsersProvider);
    final ridesAsync = ref.watch(adminAllRidesProvider);
    final requestsAsync = ref.watch(adminAllRequestsProvider);
    final postsAsync = ref.watch(adminAllPostsProvider);
    final groupsAsync = ref.watch(adminAllGroupsProvider);
    final actions = ref.read(adminActionsControllerProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: () => _logout(context, ref),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Riders'),
              Tab(text: 'Rides'),
              Tab(text: 'Requests'),
              Tab(text: 'Posts'),
              Tab(text: 'Groups'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spaceMd,
                AppDimensions.spaceMd,
                AppDimensions.spaceMd,
                AppDimensions.spaceSm,
              ),
              child: StatCardRow(
                stats: [
                  StatCard(value: '${usersAsync.value?.length ?? '—'}', label: 'Riders'),
                  StatCard(value: '${ridesAsync.value?.length ?? '—'}', label: 'Rides'),
                  StatCard(
                    value: '${requestsAsync.value?.where((r) => r.status == RideRequestStatus.pending).length ?? '—'}',
                    label: 'Pending',
                  ),
                  StatCard(value: '${postsAsync.value?.length ?? '—'}', label: 'Posts'),
                  StatCard(value: '${groupsAsync.value?.length ?? '—'}', label: 'Groups'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  usersAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(adminAllUsersProvider)),
                    data: (users) {
                      if (users.isEmpty) {
                        return const EmptyState(icon: Icons.people_outline, title: 'No riders', message: 'Riders will show up here.');
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return AdminUserRow(
                            user: user,
                            onTap: () => context.push(RouteNames.userProfilePath(user.id)),
                            onRemove: () async {
                              final confirmed = await _confirm(
                                context,
                                title: 'Remove ${user.name}?',
                                message: 'This rider will be removed from Biker Sync.',
                              );
                              if (confirmed) await actions.removeUser(user.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                  ridesAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(adminAllRidesProvider)),
                    data: (rides) {
                      if (rides.isEmpty) {
                        return const EmptyState(icon: Icons.pedal_bike_outlined, title: 'No rides', message: 'Rides will show up here.');
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(AppDimensions.spaceMd),
                        itemCount: rides.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
                        itemBuilder: (context, index) {
                          final ride = rides[index];
                          return AdminRideRow(
                            ride: ride,
                            onTap: () => context.push(RouteNames.rideDetailsPath(ride.id)),
                            onDelete: () async {
                              final confirmed = await _confirm(
                                context,
                                title: 'Delete "${ride.title}"?',
                                message: 'This ride will be removed for everyone.',
                              );
                              if (confirmed) await actions.deleteRide(ride.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                  requestsAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(adminAllRequestsProvider)),
                    data: (requests) {
                      if (requests.isEmpty) {
                        return const EmptyState(icon: Icons.inbox_outlined, title: 'No requests', message: 'Join requests will show up here.');
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(AppDimensions.spaceMd),
                        itemCount: requests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
                        itemBuilder: (context, index) {
                          final RideRequest request = requests[index];
                          return Card(
                            child: ListTile(
                              title: Text(request.userName),
                              subtitle: Text('Wants to join "${request.rideTitle}" · ${request.status.label}'),
                              onTap: () => context.push(RouteNames.rideDetailsPath(request.rideId)),
                              trailing: request.status == RideRequestStatus.pending
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                                          onPressed: () => actions.approveRequest(request.id),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                                          onPressed: () async {
                                            final reason = await showDeclineReasonDialog(context, riderName: request.userName);
                                            if (reason == null) return;
                                            await actions.declineRequest(request.id, reason: reason.isEmpty ? null : reason);
                                          },
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  postsAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(adminAllPostsProvider)),
                    data: (posts) {
                      if (posts.isEmpty) {
                        return const EmptyState(icon: Icons.groups_outlined, title: 'No posts', message: 'Community posts will show up here.');
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(AppDimensions.spaceMd),
                        itemCount: posts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return AdminPostRow(
                            post: post,
                            onDelete: () async {
                              final confirmed = await _confirm(
                                context,
                                title: 'Delete this post?',
                                message: 'This post and its comments will be removed.',
                              );
                              if (confirmed) await actions.deletePost(post.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                  groupsAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(adminAllGroupsProvider)),
                    data: (groups) {
                      if (groups.isEmpty) {
                        return const EmptyState(icon: Icons.groups_outlined, title: 'No groups', message: 'Rider groups will show up here.');
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(AppDimensions.spaceMd),
                        itemCount: groups.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
                        itemBuilder: (context, index) {
                          final Group group = groups[index];
                          return AdminGroupRow(
                            group: group,
                            onTap: () => context.push(RouteNames.groupChatPath(group.id)),
                            onDelete: () async {
                              final confirmed = await _confirm(
                                context,
                                title: 'Delete "${group.name}"?',
                                message: 'This group and its chat history will be removed for everyone.',
                              );
                              if (confirmed) await actions.deleteGroup(group.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
