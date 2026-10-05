import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/user_tile.dart';
import '../../domain/entities/follow_connection.dart';
import '../providers/profile_providers.dart';

enum FollowListType { followers, following }

/// Shows a rider's followers or the riders they follow in a bottom sheet.
Future<void> showFollowListSheet(BuildContext context, {required String userId, required FollowListType type}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FollowListSheet(userId: userId, type: type),
  );
}

class FollowListSheet extends ConsumerStatefulWidget {
  final String userId;
  final FollowListType type;

  const FollowListSheet({super.key, required this.userId, required this.type});

  @override
  ConsumerState<FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends ConsumerState<FollowListSheet> {
  final _items = <FollowConnection>[];
  String? _cursor;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = ref.read(userRepositoryProvider);
      final page = widget.type == FollowListType.followers
          ? await repository.getFollowers(widget.userId, cursor: _cursor)
          : await repository.getFollowing(widget.userId, cursor: _cursor);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is AppException ? e.message : 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == FollowListType.followers ? 'Followers' : 'Following';
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Expanded(child: _buildList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_items.isEmpty) {
      if (_error != null) return AppErrorWidget(message: _error!, onRetry: _loadMore);
      if (_isLoading) return const LoadingWidget();
      return Center(
        child: Text(
          widget.type == FollowListType.followers ? 'No followers yet.' : 'Not following anyone yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 200) _loadMore();
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
        itemCount: _items.length + (_hasMore || _error != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            if (_error != null) {
              return TextButton(onPressed: _loadMore, child: Text('$_error Tap to retry.'));
            }
            return const Padding(
              padding: EdgeInsets.all(AppDimensions.spaceSm),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final rider = _items[index];
          return UserTile(
            avatarUrl: rider.avatarUrl,
            name: rider.name,
            subtitle: rider.location,
            trailing: rider.isFollowing ? const Icon(Icons.check, size: 18) : null,
            onTap: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.push(RouteNames.userProfilePath(rider.id));
            },
          );
        },
      ),
    );
  }
}
