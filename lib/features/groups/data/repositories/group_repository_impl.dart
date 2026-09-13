import '../../domain/entities/group.dart';
import '../../domain/entities/group_message.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_local_datasource.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupLocalDataSource _dataSource;

  GroupRepositoryImpl(this._dataSource);

  @override
  Future<List<Group>> getPopularGroups() async {
    final dtos = await _dataSource.getPopularGroups();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<Group>> getMyGroups() async {
    final dtos = await _dataSource.getMyGroups();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<Group>> getAllGroups() async {
    final dtos = await _dataSource.getAllGroups();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Group> getGroupById(String groupId) async {
    final dto = await _dataSource.getGroupById(groupId);
    return dto.toEntity();
  }

  @override
  Future<Group> joinGroup(String groupId) async {
    final dto = await _dataSource.joinGroup(groupId);
    return dto.toEntity();
  }

  @override
  Future<void> leaveGroup(String groupId) => _dataSource.leaveGroup(groupId);

  @override
  Future<Group> createGroup({required String name, required String description}) async {
    final dto = await _dataSource.createGroup(name: name, description: description);
    return dto.toEntity();
  }

  @override
  Future<void> deleteGroup(String groupId) => _dataSource.deleteGroup(groupId);

  @override
  Future<List<GroupMessage>> getGroupMessages(String groupId) async {
    final dtos = await _dataSource.getGroupMessages(groupId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<GroupMessage> sendGroupMessage({required String groupId, required String text}) async {
    final dto = await _dataSource.sendGroupMessage(groupId: groupId, text: text);
    return dto.toEntity();
  }
}
