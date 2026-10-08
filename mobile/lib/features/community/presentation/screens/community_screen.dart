import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/layouts/app_scaffold.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
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
      // New posts start from the composer card atop the feed (or this
      // action) rather than a FAB, which would collide with the shell's
      // center button.
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            tooltip: 'New post',
            onPressed: () => showPostComposerSheet(context),
            icon: const Icon(Icons.edit_note_rounded),
          ),
        ],
      ),
      body: postsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(communityPostsProvider)),
        data: (posts) {
          if (posts.isEmpty) {
            return EmptyState(
              icon: Icons.groups_outlined,
              title: 'No posts yet',
              message: 'Ride recaps and trail updates from the community will show up here.',
              actionLabel: 'Write the first post',
              onAction: () => showPostComposerSheet(context),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(communityPostsProvider),
            child: SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                itemCount: posts.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
                itemBuilder: (context, index) {
                  if (index == 0) return const _ComposerPrompt();
                  final post = posts[index - 1];
                  return CommunityPostCard(
                    post: post,
                    onTap: () => context.push(RouteNames.communityPostPath(post.id)),
                    onComment: () => context.push(RouteNames.communityPostPath(post.id)),
                    onLike: () => runCommunityAction(
                      context,
                      () => actions.toggleLike(post.id, isCurrentlyLiked: post.isLiked),
                    ),
                    onAuthorTap: () => context.push(RouteNames.userProfilePath(post.userId)),
                    onShare: () => copyPostToClipboard(context, post),
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

/// "Share a ride recap…" card at the top of the feed that opens the composer.
class _ComposerPrompt extends ConsumerWidget {
  const _ComposerPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.appColors;
    final me = ref.watch(currentUserProfileProvider).value;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showPostComposerSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceSm),
          child: Row(
            children: [
              AppAvatar(imageUrl: me?.avatarUrl, name: me?.name ?? '', size: 40),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd, vertical: 10),
                  decoration: BoxDecoration(
                    color: tokens.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  child: Text(
                    'Share a ride recap or trail update…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(color: tokens.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceXs),
              const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
              const SizedBox(width: AppDimensions.spaceXs),
            ],
          ),
        ),
      ),
    );
  }
}
