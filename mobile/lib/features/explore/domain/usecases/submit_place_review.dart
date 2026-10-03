import '../../../../core/errors/app_exception.dart';
import '../entities/place_review.dart';
import '../repositories/place_repository.dart';

class SubmitPlaceReview {
  final PlaceRepository _repository;

  SubmitPlaceReview(this._repository);

  Future<PlaceReview> call({
    required String placeId,
    required int rating,
    required bool worthIt,
    required String text,
    DateTime? visitedOn,
  }) {
    if (rating < 1 || rating > 5) {
      throw const ValidationException('Pick a rating from 1 to 5 stars.');
    }
    return _repository.submitReview(
      placeId: placeId,
      rating: rating,
      worthIt: worthIt,
      text: text.trim(),
      visitedOn: visitedOn,
    );
  }
}
