import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../../core/utils/platform_name.dart';
import '../../data/datasources/feedback_remote_datasource.dart';
import '../../data/repositories/feedback_repository_impl.dart';
import '../../domain/entities/user_feedback.dart';
import '../../domain/repositories/feedback_repository.dart';

final feedbackRemoteDataSourceProvider = Provider<FeedbackRemoteDataSource>((ref) {
  return FeedbackRemoteDataSource(ref.watch(sessionApiClientProvider));
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepositoryImpl(
    ref.watch(feedbackRemoteDataSourceProvider),
    platform: currentPlatformName(),
    appVersion: AppConstants.appVersion,
  );
});

/// Sends feedback from the form. State is the last result: `data(null)`
/// before anything is sent, `loading` while sending, `data(feedback)` once
/// the server accepted it.
class FeedbackController extends StateNotifier<AsyncValue<UserFeedback?>> {
  final FeedbackRepository _repository;

  FeedbackController(this._repository) : super(const AsyncValue.data(null));

  /// Throws the `AppException` on failure so the screen can show its message.
  Future<UserFeedback> send({required String message, FeedbackCategory? category, int? rating}) async {
    state = const AsyncValue.loading();
    try {
      final feedback = await _repository.send(message: message, category: category, rating: rating);
      state = AsyncValue.data(feedback);
      return feedback;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final feedbackControllerProvider =
    StateNotifierProvider.autoDispose<FeedbackController, AsyncValue<UserFeedback?>>((ref) {
  return FeedbackController(ref.watch(feedbackRepositoryProvider));
});
