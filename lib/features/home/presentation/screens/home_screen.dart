import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/dashboard_category_provider.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../shared/layouts/app_scaffold.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/ride_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../rides/presentation/providers/ride_providers.dart';
import '../../../messages/presentation/providers/message_providers.dart';
import '../widgets/community_preview.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recommended_riders.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);
    final unreadMessages = ref.watch(totalUnreadMessagesProvider);
    final category = ref.watch(selectedDashboardCategoryProvider);
    final ridesAsync = ref.watch(dashboardUpcomingRidesProvider);
    final postsAsync = ref.watch(communityPostsProvider);
    final ridersAsync = ref.watch(recommendedRidersProvider);

    return AppScaffold(
      safeArea: false,
      body: Column(
        children: [
          // Fixed, non-scrolling header — only the content below scrolls.
          SafeArea(
            bottom: false,
            child: profileAsync.when(
              data: (profile) => HomeHeader(
                name: profile.name,
                avatarUrl: profile.avatarUrl,
                unreadNotifications: unreadNotifications,
                unreadMessages: unreadMessages,
                onAvatarTap: () => context.go(RouteNames.profile),
                onNotificationsTap: () =>
                    context.push(RouteNames.notifications),
                onMessagesTap: () => context.push(RouteNames.messages),
              ),
              loading: () => const SizedBox(height: 96),
              error: (e, st) => const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(upcomingRidesProvider);
                ref.invalidate(communityPostsProvider);
                ref.invalidate(recommendedRidersProvider);
                ref.invalidate(notificationsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceXl),
                children: [
                  const SizedBox(height: AppDimensions.spaceSm),
                  HomeBannerCarousel(
                    banners: homeBannersFor(
                      category,
                      onInvite: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invite link copied to clipboard'),
                            ),
                          ),
                      onChallenge: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Challenge details coming soon'),
                            ),
                          ),
                      onSafety: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Safety guide coming soon'),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  QuickActions(
                    actions: [
                      QuickAction(
                        icon: Icons.add_circle_outline,
                        label: 'Create ${category.activitySingular}',
                        onTap: () => context.push(RouteNames.createRide),
                      ),
                      QuickAction(
                        icon: Icons.route_outlined,
                        label: 'My ${category.activityNoun}',
                        onTap: () => context.push(RouteNames.myRides),
                      ),
                      QuickAction(
                        icon: Icons.person_search_outlined,
                        label: 'Find Riders',
                        onTap: () => context.go(RouteNames.community),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  SectionHeader(
                    title: 'Featured ${category.activitySingular}',
                    actionLabel: 'See all',
                    onAction: () => context.go(RouteNames.rides),
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  ridesAsync.when(
                    loading: () =>
                        const SizedBox(height: 220, child: LoadingWidget()),
                    error: (e, st) => AppErrorWidget(message: e.toString()),
                    data: (rides) {
                      if (rides.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceMd,
                          ),
                          child: EmptyState(
                            title:
                                'No upcoming ${category.activityNoun.toLowerCase()}',
                            message:
                                'Check back soon or create your own ${category.activitySingular.toLowerCase()}.',
                          ),
                        );
                      }
                      final featured = rides.first;
                      final upcoming = rides.skip(1).take(6).toList();
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceMd,
                            ),
                            child: RideCard(
                              ride: featured,
                              large: true,
                              onTap: () => context.push(
                                RouteNames.rideDetailsPath(featured.id),
                              ),
                            ),
                          ),
                          if (upcoming.isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.spaceLg),
                            SectionHeader(
                              title: 'Upcoming ${category.activityNoun}',
                            ),
                            const SizedBox(height: AppDimensions.spaceSm),
                            SizedBox(
                              height: 268,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spaceMd,
                                ),
                                itemCount: upcoming.length,
                                separatorBuilder: (_, _) => const SizedBox(
                                  width: AppDimensions.spaceSm,
                                ),
                                itemBuilder: (context, index) {
                                  final ride = upcoming[index];
                                  return SizedBox(
                                    width: 220,
                                    child: RideCard(
                                      ride: ride,
                                      onTap: () => context.push(
                                        RouteNames.rideDetailsPath(ride.id),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  SectionHeader(
                    title: 'Community',
                    actionLabel: 'See all',
                    onAction: () => context.go(RouteNames.community),
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  postsAsync.when(
                    loading: () =>
                        const SizedBox(height: 100, child: LoadingWidget()),
                    error: (e, st) => AppErrorWidget(message: e.toString()),
                    data: (posts) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceMd,
                      ),
                      child: Column(
                        children: [
                          for (final post in posts.take(2)) ...[
                            CommunityPreviewCard(
                              post: post,
                              onTap: () => context.push(
                                RouteNames.communityPostPath(post.id),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spaceSm),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  const SectionHeader(title: 'Recommended Riders'),
                  const SizedBox(height: AppDimensions.spaceSm),
                  ridersAsync.when(
                    loading: () =>
                        const SizedBox(height: 180, child: LoadingWidget()),
                    error: (e, st) => AppErrorWidget(message: e.toString()),
                    data: (riders) {
                      if (riders.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceMd,
                          ),
                          itemCount: riders.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppDimensions.spaceSm),
                          itemBuilder: (context, index) {
                            final rider = riders[index];
                            return RecommendedRiderCard(
                              rider: rider,
                              onTap: () => context.push(
                                RouteNames.userProfilePath(rider.id),
                              ),
                              onFollow: () => ref
                                  .read(profileControllerProvider)
                                  .toggleFollow(
                                    rider.id,
                                    isCurrentlyFollowing: rider.isFollowing,
                                  ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
