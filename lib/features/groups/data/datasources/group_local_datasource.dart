import '../../../../core/constants/app_constants.dart';
import '../../../../core/dummy/dummy_people.dart';
import '../../../../core/errors/app_exception.dart';
import '../dto/group_dto.dart';
import '../dto/group_message_dto.dart';

class GroupLocalDataSource {
  GroupLocalDataSource() {
    _groups = _seedGroups();
    _messages = _seedMessages();
  }

  late final List<GroupDto> _groups;
  late final Map<String, List<GroupMessageDto>> _messages;
  int _groupSeq = 100;
  int _messageSeq = 100;

  Future<List<GroupDto>> getPopularGroups() async {
    await Future.delayed(AppConstants.dataSourceDelay);
    return List.of(_groups)..sort((a, b) => b.memberCount.compareTo(a.memberCount));
  }

  Future<List<GroupDto>> getMyGroups() async {
    await Future.delayed(AppConstants.dataSourceDelay);
    return _groups.where((g) => g.isJoined).toList();
  }

  Future<List<GroupDto>> getAllGroups() async {
    await Future.delayed(AppConstants.dataSourceDelay);
    return List.of(_groups)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<GroupDto> getGroupById(String groupId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    return _groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw const NotFoundException('This group no longer exists.'),
    );
  }

  Future<GroupDto> joinGroup(String groupId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) throw const NotFoundException('This group no longer exists.');
    final updated = _groups[index].copyWith(isJoined: true, memberCount: _groups[index].memberCount + 1);
    _groups[index] = updated;
    _messages.putIfAbsent(groupId, () => []);
    return updated;
  }

  Future<void> leaveGroup(String groupId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) throw const NotFoundException('This group no longer exists.');
    final current = _groups[index];
    _groups[index] = current.copyWith(isJoined: false, memberCount: (current.memberCount - 1).clamp(0, 1 << 31));
  }

  Future<GroupDto> createGroup({required String name, required String description}) async {
    await Future.delayed(AppConstants.dataSourceDelay);
    final group = GroupDto(
      id: 'g_${_groupSeq++}',
      name: name,
      description: description,
      memberCount: 1,
      isJoined: true,
      organizerId: DummyPeople.me.id,
      organizerName: DummyPeople.me.name,
      createdAt: DateTime.now(),
    );
    _groups.insert(0, group);
    _messages[group.id] = [];
    return group;
  }

  Future<void> deleteGroup(String groupId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _groups.removeWhere((g) => g.id == groupId);
    _messages.remove(groupId);
  }

  Future<List<GroupMessageDto>> getGroupMessages(String groupId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    return List.of(_messages[groupId] ?? const []);
  }

  Future<GroupMessageDto> sendGroupMessage({required String groupId, required String text}) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final message = GroupMessageDto(
      id: 'gm_${_messageSeq++}',
      groupId: groupId,
      senderId: DummyPeople.me.id,
      senderName: DummyPeople.me.name,
      senderAvatarUrl: DummyPeople.me.avatarUrl,
      text: text,
      sentAt: DateTime.now(),
      isMe: true,
    );
    _messages.putIfAbsent(groupId, () => []).add(message);
    return message;
  }

  List<GroupDto> _seedGroups() {
    final now = DateTime.now();
    return [
      GroupDto(
        id: 'g_001',
        name: 'Kathmandu Riders',
        description: 'The valley\'s largest road cycling crew — sunrise rides, ring road loops, and monthly meetups.',
        coverImageUrl: 'https://picsum.photos/seed/kathmandu-riders/900/600',
        memberCount: 342,
        isJoined: true,
        organizerId: DummyPeople.aarav.id,
        organizerName: DummyPeople.aarav.name,
        createdAt: now.subtract(const Duration(days: 420)),
      ),
      GroupDto(
        id: 'g_002',
        name: 'Pulsar Bike Riders Nepal',
        description: 'For Pulsar owners and motorbike touring fans — highway runs, maintenance tips, and group rides.',
        coverImageUrl: 'https://picsum.photos/seed/pulsar-bike-riders/900/600',
        memberCount: 518,
        isJoined: false,
        organizerId: DummyPeople.suresh.id,
        organizerName: DummyPeople.suresh.name,
        createdAt: now.subtract(const Duration(days: 610)),
      ),
      GroupDto(
        id: 'g_003',
        name: 'Trail Blazers MTB',
        description: 'Mountain bikers chasing singletrack and technical descents around the valley rim.',
        coverImageUrl: 'https://picsum.photos/seed/trail-blazers-mtb/900/600',
        memberCount: 187,
        isJoined: true,
        organizerId: DummyPeople.nischal.id,
        organizerName: DummyPeople.nischal.name,
        createdAt: now.subtract(const Duration(days: 260)),
      ),
      GroupDto(
        id: 'g_004',
        name: 'Himalayan Hikers Club',
        description: 'Weekend treks, acclimatization hikes, and trip planning for the hills around Kathmandu.',
        coverImageUrl: 'https://picsum.photos/seed/himalayan-hikers/900/600',
        memberCount: 264,
        isJoined: false,
        organizerId: DummyPeople.anita.id,
        organizerName: DummyPeople.anita.name,
        createdAt: now.subtract(const Duration(days: 190)),
      ),
      GroupDto(
        id: 'g_005',
        name: 'Weekend Warriors',
        description: 'Casual, no-drop rides for anyone who just wants good company and a coffee stop.',
        coverImageUrl: 'https://picsum.photos/seed/weekend-warriors/900/600',
        memberCount: 96,
        isJoined: false,
        organizerId: DummyPeople.kabita.id,
        organizerName: DummyPeople.kabita.name,
        createdAt: now.subtract(const Duration(days: 75)),
      ),
    ];
  }

  Map<String, List<GroupMessageDto>> _seedMessages() {
    final now = DateTime.now();
    DateTime t(int minutesAgo) => now.subtract(Duration(minutes: minutesAgo));

    return {
      'g_001': [
        GroupMessageDto(
          id: 'gm_001',
          groupId: 'g_001',
          senderId: DummyPeople.aarav.id,
          senderName: DummyPeople.aarav.name,
          senderAvatarUrl: DummyPeople.aarav.avatarUrl,
          text: 'Sunrise ride this Saturday, Ratna Park, 5:30am. Who\'s in?',
          sentAt: t(240),
          isMe: false,
        ),
        GroupMessageDto(
          id: 'gm_002',
          groupId: 'g_001',
          senderId: DummyPeople.roshani.id,
          senderName: DummyPeople.roshani.name,
          senderAvatarUrl: DummyPeople.roshani.avatarUrl,
          text: 'Count me in! Bringing a friend too.',
          sentAt: t(210),
          isMe: false,
        ),
        GroupMessageDto(
          id: 'gm_003',
          groupId: 'g_001',
          senderId: DummyPeople.me.id,
          senderName: DummyPeople.me.name,
          senderAvatarUrl: DummyPeople.me.avatarUrl,
          text: 'Same, see everyone there!',
          sentAt: t(180),
          isMe: true,
        ),
      ],
      'g_003': [
        GroupMessageDto(
          id: 'gm_010',
          groupId: 'g_003',
          senderId: DummyPeople.nischal.id,
          senderName: DummyPeople.nischal.name,
          senderAvatarUrl: DummyPeople.nischal.avatarUrl,
          text: 'Shivapuri trail is in great shape after the rain, way less dust.',
          sentAt: t(500),
          isMe: false,
        ),
        GroupMessageDto(
          id: 'gm_011',
          groupId: 'g_003',
          senderId: DummyPeople.me.id,
          senderName: DummyPeople.me.name,
          senderAvatarUrl: DummyPeople.me.avatarUrl,
          text: 'Good to know, been meaning to get back up there.',
          sentAt: t(480),
          isMe: true,
        ),
      ],
    };
  }
}
