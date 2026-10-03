import '../repositories/place_repository.dart';

class ToggleSavePlace {
  final PlaceRepository _repository;

  ToggleSavePlace(this._repository);

  Future<void> call(String placeId, {required bool isCurrentlySaved}) =>
      isCurrentlySaved ? _repository.unsavePlace(placeId) : _repository.savePlace(placeId);
}
