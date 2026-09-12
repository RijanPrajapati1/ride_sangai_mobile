import '../../domain/entities/ride_request.dart';
import '../../domain/repositories/ride_request_repository.dart';
import '../datasources/ride_request_local_datasource.dart';

class RideRequestRepositoryImpl implements RideRequestRepository {
  final RideRequestLocalDataSource _dataSource;

  RideRequestRepositoryImpl(this._dataSource);

  @override
  Future<List<RideRequest>> getRequestsForOrganizer(String organizerId) async {
    final dtos = await _dataSource.getRequestsForOrganizer(organizerId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<void> approve(String requestId) => _dataSource.approve(requestId);

  @override
  Future<void> decline(String requestId, {String? reason}) =>
      _dataSource.decline(requestId, reason: reason);

  @override
  Future<List<RideRequest>> getAllRequests() async {
    final dtos = await _dataSource.getAllRequests();
    return dtos.map((d) => d.toEntity()).toList();
  }
}
