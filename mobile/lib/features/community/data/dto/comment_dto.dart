import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/comment.dart';

/// Matches the API's `Comment`.
class CommentDto {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String text;
  final DateTime time;
  final int likeCount;
  final bool isLiked;
  final bool isMine;

  const CommentDto({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.text,
    required this.time,
    this.likeCount = 0,
    this.isLiked = false,
    this.isMine = false,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) => CommentDto(
        id: json['id'] as String,
        postId: json['postId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userAvatarUrl: json['userAvatarUrl'] as String? ?? '',
        text: json['text'] as String,
        time: parseDate(json['time']),
        likeCount: json['likeCount'] as int? ?? 0,
        isLiked: json['isLiked'] as bool? ?? false,
        isMine: json['isMine'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'text': text,
        'time': toApiDate(time),
        'likeCount': likeCount,
        'isLiked': isLiked,
        'isMine': isMine,
      };

  Comment toEntity() => Comment(
        id: id,
        postId: postId,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        text: text,
        time: time,
        likeCount: likeCount,
        isLiked: isLiked,
        isMine: isMine,
      );
}
