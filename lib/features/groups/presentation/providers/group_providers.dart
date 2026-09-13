import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/group_local_datasource.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_message.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/usecases/create_group.dart';
import '../../domain/usecases/join_group.dart';
import '../../domain/usecases/leave_group.dart';
import '../../domain/usecases/send_group_message.dart';

final groupLocalDataSourceProvider = Provider<GroupLocalDataSource>((ref) {
  return GroupLocalDataSource();
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl(ref.watch(groupLocalDataSourceProvider));
});

final popularGroupsProvider = FutureProvider<List<Group>>((ref) {
  return ref.watch(groupRepositoryProvider).getPopularGroups();
});

final myGroupsProvider = FutureProvider<List<Group>>((ref) {
  return ref.watch(groupRepositoryProvider).getMyGroups();
});

final groupDetailsProvider = FutureProvider.family<Group, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getGroupById(groupId);
});

final groupMessagesProvider = FutureProvider.family<List<GroupMessage>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).getGroupMessages(groupId);
});

final groupActionsControllerProvider = Provider((ref) => GroupActionsController(ref));

class GroupActionsController {
  final Ref _ref;

  GroupActionsController(this._ref);

  Future<void> join(String groupId) async {
    await JoinGroup(_ref.read(groupRepositoryProvider))(groupId);
    _invalidate(groupId);
  }

  Future<void> leave(String groupId) async {
    await LeaveGroup(_ref.read(groupRepositoryProvider))(groupId);
    _invalidate(groupId);
  }

  Future<Group> create({required String name, required String description}) async {
    final group = await CreateGroup(_ref.read(groupRepositoryProvider))(name: name, description: description);
    _ref.invalidate(popularGroupsProvider);
    _ref.invalidate(myGroupsProvider);
    return group;
  }

  Future<void> sendMessage({required String groupId, required String text}) async {
    await SendGroupMessage(_ref.read(groupRepositoryProvider))(groupId: groupId, text: text);
    _ref.invalidate(groupMessagesProvider(groupId));
  }

  void _invalidate(String groupId) {
    _ref.invalidate(popularGroupsProvider);
    _ref.invalidate(myGroupsProvider);
    _ref.invalidate(groupDetailsProvider(groupId));
  }
}
