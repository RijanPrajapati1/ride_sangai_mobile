import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/user_feedback.dart';

/// Body of `POST /feedback`. Optional fields are left out when null.
class SendFeedbackDto {
  /// The server's limit for [message].
  static const maxMessageLength = 2000;

  final String message;
  final String? category;
  final int? rating;
  final String? platform;
  final String? appVersion;

  const SendFeedbackDto({
    required this.message,
    this.category,
    this.rating,
    this.platform,
    this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'message': message.trim(),
        if (category != null) 'category': category,
        if (rating != null) 'rating': rating,
        if (platform != null) 'platform': platform,
        if (appVersion != null) 'appVersion': appVersion,
      };
}

/// Matches the API's `Feedback` response.
class FeedbackDto {
  final String id;
  final String category;
  final int? rating;
  final String message;
  final String status;
  final DateTime createdAt;

  const FeedbackDto({
    required this.id,
    required this.category,
    required this.rating,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory FeedbackDto.fromJson(Map<String, dynamic> json) => FeedbackDto(
        id: json['id'] as String,
        category: json['category'] as String? ?? 'other',
        rating: (json['rating'] as num?)?.toInt(),
        message: json['message'] as String? ?? '',
        status: json['status'] as String? ?? 'open',
        createdAt: parseDate(json['createdAt']),
      );

  UserFeedback toEntity() => UserFeedback(
        id: id,
        category: enumByName(FeedbackCategory.values, category, FeedbackCategory.other),
        rating: rating,
        message: message,
        status: enumByName(FeedbackStatus.values, status, FeedbackStatus.open),
        createdAt: createdAt,
      );
}
