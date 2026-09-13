import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/group.dart';
import '../providers/group_providers.dart';
import '../widgets/group_card.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Groups'),
          bottom: const TabBar(tabs: [Tab(text: 'Popular'), Tab(text: 'My Groups')]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(RouteNames.createGroup),
          icon: const Icon(Icons.add),
          label: const Text('New group'),
        ),
        body: TabBarView(
          children: [
            _GroupList(provider: popularGroupsProvider, emptyMessage: 'No groups yet — be the first to start one.'),
            _GroupList(provider: myGroupsProvider, emptyMessage: 'Join a group to see it here.'),
          ],
        ),
      ),
    );
  }
}

class _GroupList extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<Group>>> provider;
  final String emptyMessage;

  const _GroupList({required this.provider, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(provider);
    final actions = ref.read(groupActionsControllerProvider);

    return groupsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, st) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(provider)),
      data: (groups) {
        if (groups.isEmpty) {
          return EmptyState(icon: Icons.groups_outlined, title: 'No groups', message: emptyMessage);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceMd,
              AppDimensions.spaceMd,
              AppDimensions.spaceMd,
              AppDimensions.spaceXxl,
            ),
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spaceSm),
            itemBuilder: (context, index) {
              final group = groups[index];
              return GroupCard(
                group: group,
                onTap: () => context.push(RouteNames.groupChatPath(group.id)),
                onJoinToggle: () => group.isJoined ? actions.leave(group.id) : actions.join(group.id),
              );
            },
          ),
        );
      },
    );
  }
}
