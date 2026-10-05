import '../entities/user_feedback.dart';

abstract class FeedbackRepository {
  /// Sends feedback to the superadmin team. The device platform and app
  /// version are attached automatically.
  Future<UserFeedback> send({
    required String message,
    FeedbackCategory? category,
    int? rating,
  });
}
