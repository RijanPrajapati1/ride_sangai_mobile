import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/enums/notification_type.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/layouts/app_scaffold.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/notification_tile.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  /// Where tapping a notification should go, or null if there is no screen
  /// for its target.
  static String? routeFor(NotificationItem notification) {
    final id = notification.entityId;
    if (id == null) {
      return notification.type == NotificationType.newMessage ? RouteNames.messages : null;
    }
    return switch (notification.entityType) {
      NotificationEntityType.ride => notification.type == NotificationType.newRideRequest
          ? RouteNames.rideRequestsPath(id)
          : RouteNames.rideDetailsPath(id),
      NotificationEntityType.post => RouteNames.communityPostPath(id),
      NotificationEntityType.user => RouteNames.userProfilePath(id),
      NotificationEntityType.conversation => RouteNames.conversationPath(id),
      NotificationEntityType.place => RouteNames.placeDetailsPath(id),
      NotificationEntityType.rideRequest ||
      NotificationEntityType.comment ||
      NotificationEntityType.group ||
      null =>
        notification.type == NotificationType.newMessage ? RouteNames.messages : null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final actions = ref.read(notificationActionsControllerProvider);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } on AppException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }

    final hasUnread = (notificationsAsync.valueOrNull?.unreadCount ?? 0) > 0;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: hasUnread ? () => run(actions.markAllAsRead) : null,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(notificationsProvider)),
        data: (feed) {
          final notifications = feed.items;
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'You\'re all caught up',
              message: 'New activity about your rides will show up here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: ValueKey(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onError),
                  ),
                  onDismissed: (_) => run(() => actions.delete(notification.id)),
                  child: NotificationTile(
                    notification: notification,
                    onTap: () {
                      if (!notification.isRead) run(() => actions.markAsRead(notification.id));
                      final route = routeFor(notification);
                      if (route != null) context.push(route);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
