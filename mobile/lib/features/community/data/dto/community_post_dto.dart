import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/community_post.dart';

/// Matches the API's `CommunityPost`.
class CommunityPostDto {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final DateTime time;
  final String text;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isMine;

  const CommunityPostDto({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.time,
    required this.text,
    this.imageUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isMine = false,
  });

  factory CommunityPostDto.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl'] as String?;
    return CommunityPostDto(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String? ?? '',
      time: parseDate(json['time']),
      text: json['text'] as String,
      imageUrl: image == null || image.isEmpty ? null : image,
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isMine: json['isMine'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'time': toApiDate(time),
        'text': text,
        'imageUrl': imageUrl,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'isLiked': isLiked,
        'isMine': isMine,
      };

  CommunityPost toEntity() => CommunityPost(
        id: id,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        time: time,
        text: text,
        imageUrl: imageUrl,
        likeCount: likeCount,
        commentCount: commentCount,
        isLiked: isLiked,
        isMine: isMine,
      );
}
