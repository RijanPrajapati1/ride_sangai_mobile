/// What the feedback is about. Names match the API's values.
enum FeedbackCategory {
  bug,
  idea,
  praise,
  other;

  String get label => switch (this) {
        FeedbackCategory.bug => 'Bug',
        FeedbackCategory.idea => 'Idea',
        FeedbackCategory.praise => 'Praise',
        FeedbackCategory.other => 'Other',
      };
}

/// Where the superadmin team is with the feedback.
enum FeedbackStatus {
  open,
  inProgress,
  resolved,
}

/// Feedback a rider sent about the app (named to avoid clashing with
/// Flutter's `Feedback` class).
class UserFeedback {
  final String id;
  final FeedbackCategory category;

  /// 1–5 stars, or null when the rider didn't rate.
  final int? rating;
  final String message;
  final FeedbackStatus status;
  final DateTime createdAt;

  const UserFeedback({
    required this.id,
    required this.category,
    required this.rating,
    required this.message,
    required this.status,
    required this.createdAt,
  });
}
