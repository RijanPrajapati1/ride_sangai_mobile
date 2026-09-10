import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';

class UpdateProfile {
  final UserRepository _repository;

  const UpdateProfile(this._repository);

  Future<UserProfile> call(UserProfile profile) => _repository.updateProfile(profile);
}
