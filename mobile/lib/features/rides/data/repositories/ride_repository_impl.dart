import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/paginated.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_participant.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/ride_remote_datasource.dart';
import '../dto/ride_dto.dart';

class RideRepositoryImpl implements RideRepository {
  /// Lists are loaded page by page up to this many items.
  static const _pageSize = 100;
  static const _maxPages = 5;

  final RideRemoteDataSource _dataSource;

  /// The signed-in rider's id ('' when signed out), used to pick `/me/...`
  /// endpoints for the rider's own lists.
  final String Function() _currentUserId;

  RideRepositoryImpl(this._dataSource, this._currentUserId);

  /// Follows `nextCursor` until the last page (or [_maxPages]).
  Future<List<T>> _all<T>(Future<Paginated<T>> Function(String? cursor) load) async {
    final items = <T>[];
    String? cursor;
    for (var page = 0; page < _maxPages; page++) {
      final result = await load(cursor);
      items.addAll(result.items);
      if (!result.hasMore) break;
      cursor = result.nextCursor;
    }
    return items;
  }

  Future<List<Ride>> _rides(Future<Paginated<RideDto>> Function(String? cursor) load) async {
    final dtos = await _all(load);
    return dtos.map((d) => d.toEntity()).toList();
  }

  bool _isMe(String userId) => userId.isNotEmpty && userId == _currentUserId();

  void _requireMe(String userId) {
    if (!_isMe(userId)) {
      throw const ForbiddenException("You can only see your own joined and past rides.");
    }
  }

  @override
  Future<List<Ride>> getUpcomingRides({
    DashboardCategory? category,
    RideType? rideType,
    RideDifficulty? difficulty,
    String? query,
    DateTime? from,
    DateTime? to,
  }) =>
      _rides((cursor) => _dataSource.getUpcomingRides(
            category: category,
            rideType: rideType,
            difficulty: difficulty,
            query: query,
            from: from,
            to: to,
            cursor: cursor,
            limit: _pageSize,
          ));

  @override
  Future<Ride> getRideById(String id) async => (await _dataSource.getRideById(id)).toEntity();

  @override
  Future<List<RideParticipant>> getParticipants(String rideId) async {
    final dtos = await _all((cursor) => _dataSource.getParticipants(rideId, cursor: cursor, limit: _pageSize));
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<Ride>> getOrganizedRides(String organizerId) {
    if (_isMe(organizerId)) {
      return _rides((cursor) => _dataSource.getMyRides(MyRidesScope.organized, cursor: cursor, limit: _pageSize));
    }
    return _rides((cursor) => _dataSource.getUserRides(organizerId, cursor: cursor, limit: _pageSize));
  }

  @override
  Future<List<Ride>> getJoinedRides(String userId) async {
    _requireMe(userId);
    return _rides((cursor) => _dataSource.getMyRides(MyRidesScope.joined, cursor: cursor, limit: _pageSize));
  }

  @override
  Future<List<Ride>> getPastRides(String userId) async {
    _requireMe(userId);
    return _rides((cursor) => _dataSource.getMyRides(MyRidesScope.past, cursor: cursor, limit: _pageSize));
  }

  @override
  Future<List<Ride>> getMyUpcomingRides() =>
      _rides((cursor) => _dataSource.getMyRides(MyRidesScope.upcoming, cursor: cursor, limit: _pageSize));

  @override
  Future<void> requestToJoin(String rideId, {String? message}) =>
      _dataSource.requestToJoin(rideId, message: message);

  @override
  Future<void> cancelRequest(String rideId) => _dataSource.cancelRequest(rideId);

  @override
  Future<Ride> createRide({
    required String title,
    required String description,
    required DateTime date,
    required String meetingPoint,
    required RideType rideType,
    required RideDifficulty difficulty,
    required double distanceKm,
    required int durationMinutes,
    required int maxParticipants,
    required List<String> requirements,
    String? imageUrl,
  }) async {
    final dto = await _dataSource.createRide(RideInputDto(
      title: title,
      description: description,
      date: date,
      meetingPoint: meetingPoint,
      rideType: rideType,
      difficulty: difficulty,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      maxParticipants: maxParticipants,
      requirements: requirements,
      imageUrl: imageUrl,
    ));
    return dto.toEntity();
  }

  @override
  Future<Ride> updateRide(
    String rideId, {
    String? title,
    String? description,
    DateTime? date,
    String? meetingPoint,
    RideType? rideType,
    RideDifficulty? difficulty,
    double? distanceKm,
    int? durationMinutes,
    int? maxParticipants,
    List<String>? requirements,
    String? imageUrl,
  }) async {
    final dto = await _dataSource.updateRide(
      rideId,
      RideInputDto(
        title: title,
        description: description,
        date: date,
        meetingPoint: meetingPoint,
        rideType: rideType,
        difficulty: difficulty,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        maxParticipants: maxParticipants,
        requirements: requirements,
        imageUrl: imageUrl,
      ),
    );
    return dto.toEntity();
  }

  @override
  Future<void> cancelRide(String rideId) => _dataSource.cancelRide(rideId);

  @override
  Future<List<Ride>> getAllRides() =>
      _rides((cursor) => _dataSource.getAllRides(cursor: cursor, limit: _pageSize));

  @override
  Future<void> deleteRide(String rideId) => _dataSource.deleteRide(rideId);
}
