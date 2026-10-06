import '../../domain/entities/user_feedback.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_datasource.dart';
import '../dto/feedback_dto.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource _remote;

  /// For example `android`, `ios` or `web` (see `currentPlatformName`).
  final String platform;
  final String appVersion;

  FeedbackRepositoryImpl(this._remote, {required this.platform, required this.appVersion});

  @override
  Future<UserFeedback> send({required String message, FeedbackCategory? category, int? rating}) async {
    final dto = await _remote.send(SendFeedbackDto(
      message: message,
      category: category?.name,
      rating: rating,
      platform: platform,
      appVersion: appVersion,
    ));
    return dto.toEntity();
  }
}
