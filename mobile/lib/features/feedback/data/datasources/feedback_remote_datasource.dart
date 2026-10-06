import '../../../../core/network/api_client.dart';
import '../dto/feedback_dto.dart';

/// Calls `POST /feedback`. Only knows about HTTP and JSON.
class FeedbackRemoteDataSource {
  final ApiClient _api;

  FeedbackRemoteDataSource(this._api);

  static const feedback = '/feedback';

  /// Requires a signed-in user. The server allows 10 per hour per user
  /// (`429 RATE_LIMITED` after that).
  Future<FeedbackDto> send(SendFeedbackDto body) async {
    final json = await _api.post<Map<String, dynamic>>(feedback, data: body.toJson());
    return FeedbackDto.fromJson(json);
  }
}
