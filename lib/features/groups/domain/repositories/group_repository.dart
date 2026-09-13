import '../entities/group.dart';
import '../entities/group_message.dart';

abstract class GroupRepository {
  Future<List<Group>> getPopularGroups();
  Future<List<Group>> getMyGroups();
  Future<List<Group>> getAllGroups();
  Future<Group> getGroupById(String groupId);
  Future<Group> joinGroup(String groupId);
  Future<void> leaveGroup(String groupId);
  Future<Group> createGroup({required String name, required String description});
  Future<void> deleteGroup(String groupId);
  Future<List<GroupMessage>> getGroupMessages(String groupId);
  Future<GroupMessage> sendGroupMessage({required String groupId, required String text});
}
