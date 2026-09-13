import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/layouts/app_scaffold.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../../groups/presentation/widgets/group_card.dart';
import '../providers/community_providers.dart';
import '../widgets/community_post_card.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityPostsProvider);
    final groupsAsync = ref.watch(popularGroupsProvider);
    final actions = ref.read(communityActionsControllerProvider);

    return AppScaffold(
      safeArea: false,
      appBar: AppBar(title: const Text('Community')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(communityPostsProvider);
            ref.invalidate(popularGroupsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
            children: [
              SectionHeader(
                title: 'Popular Groups',
                actionLabel: 'See all',
                onAction: () => context.push(RouteNames.groups),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              SizedBox(
                height: 254,
                child: groupsAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(popularGroupsProvider)),
                  data: (groups) {
                    if (groups.isEmpty) {
                      return const EmptyState(
                        icon: Icons.groups_outlined,
                        title: 'No groups yet',
                        message: 'Start a group for your crew.',
                      );
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.spaceSm),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return SizedBox(
                          width: 220,
                          child: GroupCard(
                            group: group,
                            onTap: () => context.push(RouteNames.groupChatPath(group.id)),
                            onJoinToggle: () {
                              final groupActions = ref.read(groupActionsControllerProvider);
                              group.isJoined ? groupActions.leave(group.id) : groupActions.join(group.id);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              const SectionHeader(title: 'Community Feed'),
              const SizedBox(height: AppDimensions.spaceSm),
              postsAsync.when(
                loading: () => const SizedBox(height: 160, child: LoadingWidget()),
                error: (e, st) => SizedBox(
                  height: 160,
                  child: AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(communityPostsProvider)),
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return const SizedBox(
                      height: 220,
                      child: EmptyState(
                        icon: Icons.forum_outlined,
                        title: 'No posts yet',
                        message: 'Ride recaps and updates from the community will show up here.',
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
                    child: Column(
                      children: [
                        for (var i = 0; i < posts.length; i++) ...[
                          CommunityPostCard(
                            post: posts[i],
                            onTap: () => context.push(RouteNames.communityPostPath(posts[i].id)),
                            onComment: () => context.push(RouteNames.communityPostPath(posts[i].id)),
                            onLike: () => actions.toggleLike(posts[i].id, isCurrentlyLiked: posts[i].isLiked),
                            onAuthorTap: () => context.push(RouteNames.userProfilePath(posts[i].userId)),
                            onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied to clipboard')),
                            ),
                          ),
                          if (i != posts.length - 1) const SizedBox(height: AppDimensions.spaceSm),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
