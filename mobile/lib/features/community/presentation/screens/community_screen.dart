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
import '../widgets/community_action_helpers.dart';
import '../widgets/community_post_card.dart';
import '../widgets/post_composer_sheet.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityPostsProvider);
    final actions = ref.read(communityActionsControllerProvider);

    return AppScaffold(
      safeArea: false,
      appBar: AppBar(title: const Text('Community')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'community_new_post',
        tooltip: 'New post',
        onPressed: () => showPostComposerSheet(context),
        child: const Icon(Icons.edit_outlined),
      ),
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
                    onLike: () => runCommunityAction(
                      context,
                      () => actions.toggleLike(post.id, isCurrentlyLiked: post.isLiked),
                    ),
                    onAuthorTap: () => context.push(RouteNames.userProfilePath(post.userId)),
                    onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    ),
                    onEdit: post.isMine ? () => showPostComposerSheet(context, post: post) : null,
                    onDelete: post.isMine
                        ? () async {
                            if (!await confirmCommunityDelete(context, what: 'post')) return;
                            if (context.mounted) await runCommunityAction(context, () => actions.deletePost(post.id));
                          }
                        : null,
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
