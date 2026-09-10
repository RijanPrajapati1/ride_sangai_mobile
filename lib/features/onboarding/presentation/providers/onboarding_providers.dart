import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../data/datasources/onboarding_local_datasource.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/repositories/onboarding_repository.dart';

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((ref) {
  return OnboardingLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(onboardingLocalDataSourceProvider));
});

final onboardingCompleteProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingRepositoryProvider).isComplete();
});

final onboardingControllerProvider = Provider((ref) => OnboardingController(ref));

class OnboardingController {
  final Ref _ref;

  OnboardingController(this._ref);

  Future<void> complete() async {
    await _ref.read(onboardingRepositoryProvider).complete();
    _ref.invalidate(onboardingCompleteProvider);
  }
}
