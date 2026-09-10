abstract class OnboardingRepository {
  Future<bool> isComplete();
  Future<void> complete();
}
