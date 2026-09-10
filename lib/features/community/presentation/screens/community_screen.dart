import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/layouts/app_scaffold.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/community_providers.dart';
import '../widgets/community_post_card.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityPostsProvider);
    final actions = ref.read(communityActionsControllerProvider);

    return AppScaffold(
      safeArea: false,
      appBar: AppBar(title: const Text('Community')),
      body: postsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(communityPostsProvider)),
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No posts yet',
              message: 'Ride recaps and updates from the community will show up here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(communityPostsProvider),
            child: SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return CommunityPostCard(
                    post: post,
                    onTap: () => context.push(RouteNames.communityPostPath(post.id)),
                    onComment: () => context.push(RouteNames.communityPostPath(post.id)),
                    onLike: () => actions.toggleLike(post.id, isCurrentlyLiked: post.isLiked),
                    onAuthorTap: () => context.push(RouteNames.userProfilePath(post.userId)),
                    onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
