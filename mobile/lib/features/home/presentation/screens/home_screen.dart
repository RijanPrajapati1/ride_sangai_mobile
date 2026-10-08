import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/dashboard_category_provider.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/dashboard_category.dart';
import '../../../../shared/utils/run_or_show_error.dart';
import '../../../../shared/layouts/app_scaffold.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/ride_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../explore/presentation/providers/explore_providers.dart';
import '../../../explore/presentation/widgets/place_card.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../rides/presentation/providers/ride_providers.dart';
import '../../../messages/presentation/providers/message_providers.dart';
import '../widgets/community_preview.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recommended_riders.dart';
import '../widgets/safety_checklist_sheet.dart';

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
    final placesAsync = ref.watch(homeExplorePlacesProvider);
    // Horizontal carousels need a fixed height; grow it with the rider's
    // text size so card text never gets cut off.
    final textGrowth = MediaQuery.textScalerOf(context).scale(10) / 10 - 1;

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
              loading: () => const SizedBox(height: 68),
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
                ref.invalidate(homeExplorePlacesProvider);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceXl),
                children: [
                  const SizedBox(height: AppDimensions.spaceXs),
                  DashboardCategoryChips(
                    selected: category,
                    onChanged: (picked) => ref.read(selectedDashboardCategoryProvider.notifier).select(picked),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  HomeBannerCarousel(
                    banners: homeBannersFor(
                      category,
                      onCreate: () => context.push(RouteNames.createRide),
                      onExplore: () => context.push(RouteNames.explore),
                      onSafety: () => showSafetyChecklistSheet(context, category),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  // Creating a ride lives on the center nav button, so these
                  // are the shortcuts that have no tab of their own.
                  QuickActions(
                    actions: [
                      QuickAction(
                        icon: Icons.event_note_rounded,
                        label: 'My ${category.activityNoun}',
                        color: AppColors.primary,
                        onTap: () => context.push(RouteNames.myRides),
                      ),
                      QuickAction(
                        icon: Icons.travel_explore_rounded,
                        label: 'Explore',
                        color: AppColors.info,
                        onTap: () => context.push(RouteNames.explore),
                      ),
                      QuickAction(
                        icon: Icons.bookmark_rounded,
                        label: 'Saved',
                        color: AppColors.secondary,
                        onTap: () => context.push(RouteNames.savedPlaces),
                      ),
                      QuickAction(
                        icon: Icons.add_location_alt_rounded,
                        label: 'Share place',
                        color: AppColors.violet,
                        onTap: () => context.push(RouteNames.sharePlace),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  SectionHeader(
                    title: 'Featured ${category.activitySingular}',
                    actionLabel: 'See all',
                    onAction: () => context.go(RouteNames.rides),
                  ),
                  const SizedBox(height: AppDimensions.spaceXs),
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
                            icon: category.icon,
                            title:
                                'No upcoming ${category.activityNoun.toLowerCase()}',
                            message:
                                'Be the first to plan one. Riders nearby can ask to join.',
                            actionLabel: 'Create a ${category.activitySingular.toLowerCase()}',
                            onAction: () => context.push(RouteNames.createRide),
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
                            const SizedBox(height: AppDimensions.spaceXs),
                            SizedBox(
                              height: 262 + 130 * textGrowth,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                padding: const EdgeInsets.fromLTRB(
                                  AppDimensions.spaceMd,
                                  2,
                                  AppDimensions.spaceMd,
                                  6,
                                ),
                                itemCount: upcoming.length,
                                separatorBuilder: (_, _) => const SizedBox(
                                  width: AppDimensions.spaceSm,
                                ),
                                itemBuilder: (context, index) {
                                  final ride = upcoming[index];
                                  return SizedBox(
                                    width: 250,
                                    child: RideCard(
                                      ride: ride,
                                      compact: true,
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
                    title: 'Explore nearby',
                    actionLabel: 'See all',
                    onAction: () => context.push(RouteNames.explore),
                  ),
                  const SizedBox(height: AppDimensions.spaceXs),
                  placesAsync.when(
                    loading: () =>
                        const SizedBox(height: 230, child: LoadingWidget()),
                    error: (e, st) => AppErrorWidget(message: e.toString()),
                    data: (places) {
                      if (places.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceMd,
                          ),
                          child: EmptyState(
                            icon: Icons.travel_explore,
                            title: 'No places nearby yet',
                            message:
                                'Know a hidden gem around here? Share it with other riders.',
                            actionLabel: 'Share a place',
                            onAction: () =>
                                context.push(RouteNames.sharePlace),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 232 + 90 * textGrowth,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.fromLTRB(
                            AppDimensions.spaceMd,
                            2,
                            AppDimensions.spaceMd,
                            6,
                          ),
                          itemCount: places.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppDimensions.spaceSm),
                          itemBuilder: (context, index) {
                            final place = places[index];
                            return SizedBox(
                              width: 240,
                              child: PlaceCard(
                                place: place,
                                compact: true,
                                onTap: () => context.push(
                                  RouteNames.placeDetailsPath(place.id),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  SectionHeader(
                    title: 'Community',
                    actionLabel: 'See all',
                    onAction: () => context.go(RouteNames.community),
                  ),
                  const SizedBox(height: AppDimensions.spaceXs),
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
                  const SectionHeader(title: 'Riders to follow'),
                  const SizedBox(height: AppDimensions.spaceXs),
                  ridersAsync.when(
                    loading: () =>
                        const SizedBox(height: 180, child: LoadingWidget()),
                    error: (e, st) => AppErrorWidget(message: e.toString()),
                    data: (riders) {
                      if (riders.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        height: 194 + 70 * textGrowth,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.fromLTRB(
                            AppDimensions.spaceMd,
                            2,
                            AppDimensions.spaceMd,
                            6,
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
                              onFollow: () => runOrShowError(
                                context,
                                () => ref
                                    .read(profileControllerProvider)
                                    .toggleFollow(rider.id, isCurrentlyFollowing: rider.isFollowing),
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
