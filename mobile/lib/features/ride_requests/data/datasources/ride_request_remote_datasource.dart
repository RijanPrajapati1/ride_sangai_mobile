import '../../../../core/enums/ride_enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated.dart';
import '../dto/ride_request_dto.dart';

/// Calls the ride join-request endpoints. Only knows about HTTP and JSON.
class RideRequestRemoteDataSource {
  static String rideRequests(String rideId) => '/rides/$rideId/requests';
  static const myRequests = '/me/ride-requests';
  static String approvePath(String requestId) => '/ride-requests/$requestId/approve';
  static String declinePath(String requestId) => '/ride-requests/$requestId/decline';
  static const superadminRequests = '/superadmin/ride-requests';

  final ApiClient _api;

  RideRequestRemoteDataSource(this._api);

  Future<Paginated<RideRequestDto>> _page(String path, Map<String, dynamic> query) async {
    final json = await _api.get<Map<String, dynamic>>(path, query: query);
    return Paginated.fromJson(json, RideRequestDto.fromJson);
  }

  /// `GET /me/ride-requests`: requests across every ride I organize.
  Future<Paginated<RideRequestDto>> getMyRideRequests({RideRequestStatus? status, String? cursor, int? limit}) =>
      _page(myRequests, {'status': status?.name, 'cursor': cursor, 'limit': limit});

  /// `GET /rides/:id/requests` (organizer or superadmin).
  Future<Paginated<RideRequestDto>> getRequestsForRide(
    String rideId, {
    RideRequestStatus? status,
    String? cursor,
    int? limit,
  }) =>
      _page(rideRequests(rideId), {'status': status?.name, 'cursor': cursor, 'limit': limit});

  Future<RideRequestDto> approve(String requestId) async {
    final json = await _api.post<Map<String, dynamic>>(approvePath(requestId));
    return RideRequestDto.fromJson(json);
  }

  Future<RideRequestDto> decline(String requestId, {String? reason}) async {
    final trimmed = reason?.trim();
    final json = await _api.post<Map<String, dynamic>>(
      declinePath(requestId),
      data: {if (trimmed != null && trimmed.isNotEmpty) 'reason': trimmed},
    );
    return RideRequestDto.fromJson(json);
  }

  /// `GET /superadmin/ride-requests`: every request, newest first.
  Future<Paginated<RideRequestDto>> getAllRequests({RideRequestStatus? status, String? cursor, int? limit}) =>
      _page(superadminRequests, {'status': status?.name, 'cursor': cursor, 'limit': limit});
}
