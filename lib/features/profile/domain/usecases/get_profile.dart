import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';

class GetProfile {
  final UserRepository _repository;

  const GetProfile(this._repository);

  Future<UserProfile> call(String userId) => _repository.getProfile(userId);
}
