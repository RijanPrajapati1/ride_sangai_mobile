import '../../../../core/enums/ride_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/paginated.dart';
import '../../domain/entities/ride_request.dart';
import '../../domain/repositories/ride_request_repository.dart';
import '../datasources/ride_request_remote_datasource.dart';
import '../dto/ride_request_dto.dart';

class RideRequestRepositoryImpl implements RideRequestRepository {
  static const _pageSize = 100;
  static const _maxPages = 5;

  final RideRequestRemoteDataSource _dataSource;
  final String Function() _currentUserId;

  RideRequestRepositoryImpl(this._dataSource, this._currentUserId);

  /// Follows `nextCursor` until the last page (or [_maxPages]).
  Future<List<RideRequest>> _all(Future<Paginated<RideRequestDto>> Function(String? cursor) load) async {
    final items = <RideRequest>[];
    String? cursor;
    for (var page = 0; page < _maxPages; page++) {
      final result = await load(cursor);
      items.addAll(result.items.map((d) => d.toEntity()));
      if (!result.hasMore) break;
      cursor = result.nextCursor;
    }
    return items;
  }

  @override
  Future<List<RideRequest>> getRequestsForOrganizer(String organizerId, {RideRequestStatus? status}) async {
    if (organizerId.isEmpty || organizerId != _currentUserId()) {
      throw const ForbiddenException("You can only see requests for rides you organize.");
    }
    return _all((cursor) => _dataSource.getMyRideRequests(status: status, cursor: cursor, limit: _pageSize));
  }

  @override
  Future<List<RideRequest>> getRequestsForRide(String rideId, {RideRequestStatus? status}) =>
      _all((cursor) => _dataSource.getRequestsForRide(rideId, status: status, cursor: cursor, limit: _pageSize));

  @override
  Future<RideRequest> approve(String requestId) async => (await _dataSource.approve(requestId)).toEntity();

  @override
  Future<RideRequest> decline(String requestId, {String? reason}) async =>
      (await _dataSource.decline(requestId, reason: reason)).toEntity();

  @override
  Future<List<RideRequest>> getAllRequests({RideRequestStatus? status}) =>
      _all((cursor) => _dataSource.getAllRequests(status: status, cursor: cursor, limit: _pageSize));
}
