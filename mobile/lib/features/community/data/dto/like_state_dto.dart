import '../../domain/entities/like_state.dart';

/// Matches the API's `LikeState`: `{ isLiked, likeCount }`.
class LikeStateDto {
  final bool isLiked;
  final int likeCount;

  const LikeStateDto({required this.isLiked, required this.likeCount});

  factory LikeStateDto.fromJson(Map<String, dynamic> json) =>
      LikeStateDto(isLiked: json['isLiked'] as bool, likeCount: json['likeCount'] as int);

  Map<String, dynamic> toJson() => {'isLiked': isLiked, 'likeCount': likeCount};

  LikeState toEntity() => LikeState(isLiked: isLiked, likeCount: likeCount);
}
