import '../../../../core/enums/dashboard_category.dart';
import '../../../../core/enums/ride_enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated.dart';
import '../../../../core/utils/json_parsing.dart';
import '../dto/ride_dto.dart';
import '../dto/ride_participant_dto.dart';

/// Which tab of `GET /me/rides` to load.
enum MyRidesScope { upcoming, organized, joined, past }

/// Calls the ride endpoints. Only knows about HTTP and JSON.
class RideRemoteDataSource {
  static const rides = '/rides';
  static String ride(String id) => '/rides/$id';
  static String participants(String id) => '/rides/$id/participants';
  static String join(String id) => '/rides/$id/join';
  static const myRides = '/me/rides';
  static String userRides(String userId) => '/users/$userId/rides';
  static const adminRides = '/admin/rides';
  static String adminRide(String id) => '/admin/rides/$id';

  final ApiClient _api;

  RideRemoteDataSource(this._api);

  Future<Paginated<RideDto>> _page(String path, Map<String, dynamic> query) async {
    final json = await _api.get<Map<String, dynamic>>(path, query: query);
    return Paginated.fromJson(json, RideDto.fromJson);
  }

  /// `GET /rides`: upcoming rides, soonest first.
  Future<Paginated<RideDto>> getUpcomingRides({
    DashboardCategory? category,
    RideType? rideType,
    RideDifficulty? difficulty,
    String? query,
    DateTime? from,
    DateTime? to,
    String? cursor,
    int? limit,
  }) =>
      _page(rides, {
        'category': category?.name,
        'rideType': rideType?.name,
        'difficulty': difficulty?.name,
        'q': (query == null || query.trim().isEmpty) ? null : query.trim(),
        'from': from == null ? null : toApiDate(from),
        'to': to == null ? null : toApiDate(to),
        'cursor': cursor,
        'limit': limit,
      });

  Future<RideDto> getRideById(String id) async {
    final json = await _api.get<Map<String, dynamic>>(ride(id));
    return RideDto.fromJson(json);
  }

  Future<Paginated<RideParticipantDto>> getParticipants(String rideId, {String? cursor, int? limit}) async {
    final json = await _api.get<Map<String, dynamic>>(
      participants(rideId),
      query: {'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, RideParticipantDto.fromJson);
  }

  /// `GET /me/rides?scope=…`: the signed-in rider's rides.
  Future<Paginated<RideDto>> getMyRides(
    MyRidesScope scope, {
    DashboardCategory? category,
    String? cursor,
    int? limit,
  }) =>
      _page(myRides, {'scope': scope.name, 'category': category?.name, 'cursor': cursor, 'limit': limit});

  /// `GET /users/:id/rides`: rides another rider organizes (all dates).
  Future<Paginated<RideDto>> getUserRides(String userId, {String? cursor, int? limit}) =>
      _page(userRides(userId), {'cursor': cursor, 'limit': limit});

  /// `POST /rides/:id/join`: creates a pending request.
  Future<void> requestToJoin(String rideId, {String? message}) => _api.post<dynamic>(
        join(rideId),
        data: {if (message != null && message.trim().isNotEmpty) 'message': message.trim()},
      );

  /// `DELETE /rides/:id/join`: withdraws a request or leaves the ride.
  Future<void> cancelRequest(String rideId) => _api.delete<dynamic>(join(rideId));

  Future<RideDto> createRide(RideInputDto body) async {
    final json = await _api.post<Map<String, dynamic>>(rides, data: body.toJson());
    return RideDto.fromJson(json);
  }

  Future<RideDto> updateRide(String rideId, RideInputDto body) async {
    final json = await _api.patch<Map<String, dynamic>>(ride(rideId), data: body.toJson());
    return RideDto.fromJson(json);
  }

  /// `DELETE /rides/:id`: the organizer (or an admin) cancels the ride.
  Future<void> cancelRide(String rideId) => _api.delete<dynamic>(ride(rideId));

  /// `GET /admin/rides`: every ride, newest start first.
  Future<Paginated<RideDto>> getAllRides({String when = 'all', String? cursor, int? limit}) =>
      _page(adminRides, {'when': when, 'cursor': cursor, 'limit': limit});

  /// `DELETE /admin/rides/:id`.
  Future<void> deleteRide(String rideId) => _api.delete<dynamic>(adminRide(rideId));
}
