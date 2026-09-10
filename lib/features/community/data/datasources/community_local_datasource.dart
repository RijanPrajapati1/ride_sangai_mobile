import '../../../../core/constants/app_constants.dart';
import '../../../../core/dummy/dummy_people.dart';
import '../../../../core/errors/app_exception.dart';
import '../dto/comment_dto.dart';
import '../dto/community_post_dto.dart';

class CommunityLocalDataSource {
  CommunityLocalDataSource() {
    _posts = _seedPosts();
    _comments = _seedComments();
  }

  late final List<CommunityPostDto> _posts;
  late final Map<String, List<CommentDto>> _comments;
  int _commentSeq = 100;

  Future<List<CommunityPostDto>> getPosts() async {
    await Future.delayed(AppConstants.dataSourceDelay);
    return List.of(_posts)..sort((a, b) => b.time.compareTo(a.time));
  }

  Future<CommunityPostDto> getPostById(String id) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final post = _posts.where((p) => p.id == id).cast<CommunityPostDto?>().firstWhere(
          (p) => p != null,
          orElse: () => null,
        );
    if (post == null) throw const NotFoundException('This post could not be found.');
    return post;
  }

  Future<List<CommentDto>> getComments(String postId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    return List.of(_comments[postId] ?? const []);
  }

  Future<CommentDto> addComment({required String postId, required String text}) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    final comment = CommentDto(
      id: 'cm_${_commentSeq++}',
      postId: postId,
      userId: DummyPeople.me.id,
      userName: DummyPeople.me.name,
      userAvatarUrl: DummyPeople.me.avatarUrl,
      text: text,
      time: DateTime.now(),
    );
    _comments.putIfAbsent(postId, () => []).add(comment);
    _updatePost(postId, commentDelta: 1);
    return comment;
  }

  Future<void> likePost(String postId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _setLiked(postId, true);
  }

  Future<void> unlikePost(String postId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _setLiked(postId, false);
  }

  Future<void> deletePost(String postId) async {
    await Future.delayed(AppConstants.shortDataSourceDelay);
    _posts.removeWhere((p) => p.id == postId);
    _comments.remove(postId);
  }

  void _setLiked(String postId, bool liked) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    if (post.isLiked == liked) return;
    _posts[index] = post.copyWith(
      isLiked: liked,
      likeCount: post.likeCount + (liked ? 1 : -1),
    );
  }

  void _updatePost(String postId, {int commentDelta = 0}) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    _posts[index] = post.copyWith(commentCount: post.commentCount + commentDelta);
  }

  List<CommunityPostDto> _seedPosts() {
    final now = DateTime.now();
    DateTime t(int hoursAgo) => now.subtract(Duration(hours: hoursAgo));

    return [
      CommunityPostDto(
        id: 'p_001',
        userId: DummyPeople.suresh.id,
        userName: DummyPeople.suresh.name,
        userAvatarUrl: DummyPeople.suresh.avatarUrl,
        time: t(2),
        text: 'Finally cracked 50km/h on the Nagarkot descent this morning. Legs are jelly '
            'but absolutely worth the sunrise view from the top. 🚵‍♂️',
        imageUrl: 'https://picsum.photos/seed/nagarkot-post/800/600',
        likeCount: 58,
        commentCount: 2,
        isLiked: true,
      ),
      CommunityPostDto(
        id: 'p_002',
        userId: DummyPeople.priya.id,
        userName: DummyPeople.priya.name,
        userAvatarUrl: DummyPeople.priya.avatarUrl,
        time: t(6),
        text: 'Yesterday\'s Bhaktapur heritage loop was pure magic — golden light on the '
            'temple roofs and a perfectly quiet Durbar Square before the crowds arrived.',
        imageUrl: 'https://picsum.photos/seed/bhaktapur-post/800/600',
        likeCount: 41,
        commentCount: 1,
      ),
      CommunityPostDto(
        id: 'p_003',
        userId: DummyPeople.dipesh.id,
        userName: DummyPeople.dipesh.name,
        userAvatarUrl: DummyPeople.dipesh.avatarUrl,
        time: t(11),
        text: 'PSA: new singletrack has opened up near Godavari — flowy, fast, and a real '
            'test on the climbs. Bringing the group there next month.',
        likeCount: 33,
        commentCount: 0,
      ),
      CommunityPostDto(
        id: 'p_004',
        userId: DummyPeople.kabita.id,
        userName: DummyPeople.kabita.name,
        userAvatarUrl: DummyPeople.kabita.avatarUrl,
        time: t(20),
        text: 'Small win: talked three coworkers into joining their first evening spin '
            'around Lalitpur. Watching people fall in love with cycling never gets old.',
        imageUrl: 'https://picsum.photos/seed/lalitpur-post/800/600',
        likeCount: 76,
        commentCount: 3,
      ),
      CommunityPostDto(
        id: 'p_005',
        userId: DummyPeople.roshani.id,
        userName: DummyPeople.roshani.name,
        userAvatarUrl: DummyPeople.roshani.avatarUrl,
        time: t(30),
        text: 'Gravel bike finally set up with wider tyres for the Dhulikhel route. Who\'s '
            'in for a sunrise test ride this weekend?',
        likeCount: 24,
        commentCount: 1,
      ),
      CommunityPostDto(
        id: 'p_006',
        userId: DummyPeople.me.id,
        userName: DummyPeople.me.name,
        userAvatarUrl: DummyPeople.me.avatarUrl,
        time: t(48),
        text: 'Hit 200km for the month! Slowly building up toward my first century ride. '
            'Thanks to everyone who\'s been pacing me on the ring road loops.',
        imageUrl: 'https://picsum.photos/seed/ring-road-post/800/600',
        likeCount: 19,
        commentCount: 0,
      ),
    ];
  }

  Map<String, List<CommentDto>> _seedComments() {
    final now = DateTime.now();
    DateTime t(int hoursAgo) => now.subtract(Duration(hours: hoursAgo));

    return {
      'p_001': [
        CommentDto(
          id: 'cm_001',
          postId: 'p_001',
          userId: DummyPeople.nischal.id,
          userName: DummyPeople.nischal.name,
          userAvatarUrl: DummyPeople.nischal.avatarUrl,
          text: 'That descent is no joke, nice work!',
          time: t(1),
          likeCount: 4,
        ),
        CommentDto(
          id: 'cm_002',
          postId: 'p_001',
          userId: DummyPeople.me.id,
          userName: DummyPeople.me.name,
          userAvatarUrl: DummyPeople.me.avatarUrl,
          text: 'Inspiring! Adding this to my bucket list.',
          time: t(1),
          likeCount: 1,
        ),
      ],
      'p_002': [
        CommentDto(
          id: 'cm_003',
          postId: 'p_002',
          userId: DummyPeople.sabina.id,
          userName: DummyPeople.sabina.name,
          userAvatarUrl: DummyPeople.sabina.avatarUrl,
          text: 'The light in that last photo is unreal.',
          time: t(5),
          likeCount: 2,
        ),
      ],
      'p_004': [
        CommentDto(
          id: 'cm_004',
          postId: 'p_004',
          userId: DummyPeople.aarav.id,
          userName: DummyPeople.aarav.name,
          userAvatarUrl: DummyPeople.aarav.avatarUrl,
          text: 'This is what it\'s all about!',
          time: t(19),
          likeCount: 5,
        ),
        CommentDto(
          id: 'cm_005',
          postId: 'p_004',
          userId: DummyPeople.bibek.id,
          userName: DummyPeople.bibek.name,
          userAvatarUrl: DummyPeople.bibek.avatarUrl,
          text: 'Bring them to the night ride next!',
          time: t(18),
          likeCount: 3,
        ),
        CommentDto(
          id: 'cm_006',
          postId: 'p_004',
          userId: DummyPeople.anita.id,
          userName: DummyPeople.anita.name,
          userAvatarUrl: DummyPeople.anita.avatarUrl,
          text: 'Love to see it 🙌',
          time: t(17),
          likeCount: 1,
        ),
      ],
      'p_005': [
        CommentDto(
          id: 'cm_007',
          postId: 'p_005',
          userId: DummyPeople.dipesh.id,
          userName: DummyPeople.dipesh.name,
          userAvatarUrl: DummyPeople.dipesh.avatarUrl,
          text: 'Count me in, what time?',
          time: t(28),
          likeCount: 0,
        ),
      ],
    };
  }
}
