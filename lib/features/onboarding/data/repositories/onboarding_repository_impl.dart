import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource _dataSource;

  OnboardingRepositoryImpl(this._dataSource);

  @override
  Future<bool> isComplete() => _dataSource.isComplete();

  @override
  Future<void> complete() => _dataSource.complete();
}
