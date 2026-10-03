import '../entities/place.dart';
import '../repositories/place_repository.dart';

class GetPlaces {
  final PlaceRepository _repository;

  GetPlaces(this._repository);

  Future<List<Place>> call(PlaceQuery query) => _repository.getPlaces(query);
}
