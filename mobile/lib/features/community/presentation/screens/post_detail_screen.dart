import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/community_providers.dart';
import '../widgets/comment_tile.dart';
import '../widgets/community_action_helpers.dart';
import '../widgets/community_post_card.dart';
import '../widgets/post_composer_sheet.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final ok = await runCommunityAction(
      context,
      () => ref.read(communityActionsControllerProvider).addComment(postId: widget.postId, text: text),
    );
    if (ok) _commentController.clear();
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _deletePost(String postId) async {
    if (!await confirmCommunityDelete(context, what: 'post')) return;
    if (!mounted) return;
    final ok = await runCommunityAction(context, () => ref.read(communityActionsControllerProvider).deletePost(postId));
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(communityPostProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final actions = ref.read(communityActionsControllerProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Post'),
      body: Column(
        children: [
          Expanded(
            child: postAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, st) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(communityPostProvider(widget.postId)),
              ),
              data: (post) => ListView(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                children: [
                  CommunityPostCard(
                    post: post,
                    onTap: () {},
                    onLike: () => runCommunityAction(
                      context,
                      () => actions.toggleLike(post.id, isCurrentlyLiked: post.isLiked),
                    ),
                    onComment: () {},
                    onAuthorTap: () => context.push(RouteNames.userProfilePath(post.userId)),
                    onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    ),
                    onEdit: post.isMine ? () => showPostComposerSheet(context, post: post) : null,
                    onDelete: post.isMine ? () => _deletePost(post.id) : null,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  Text('Comments', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(height: AppDimensions.spaceLg),
                  commentsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: LoadingWidget(),
                    ),
                    error: (e, st) => AppErrorWidget(message: e.toString()),
                    data: (comments) {
                      if (comments.isEmpty) {
                        return const EmptyState(
                          icon: Icons.mode_comment_outlined,
                          title: 'No comments yet',
                          message: 'Be the first to share your thoughts.',
                        );
                      }
                      return Column(
                        children: [
                          for (final c in comments)
                            CommentTile(
                              comment: c,
                              onLike: () => runCommunityAction(context, () => actions.toggleCommentLike(c)),
                              // The comment's author and the post's author may delete it.
                              onDelete: c.isMine || post.isMine
                                  ? () async {
                                      if (!await confirmCommunityDelete(context, what: 'comment')) return;
                                      if (context.mounted) {
                                        await runCommunityAction(context, () => actions.deleteComment(c));
                                      }
                                    }
                                  : null,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: context.appColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceSm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                        maxLength: 1000,
                        decoration: const InputDecoration(hintText: 'Add a comment…', counterText: ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _submitting ? null : _submitComment,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
