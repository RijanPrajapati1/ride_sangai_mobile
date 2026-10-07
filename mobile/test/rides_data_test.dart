import 'package:flutter_test/flutter_test.dart';
import 'package:yatrix/core/enums/dashboard_category.dart';
import 'package:yatrix/core/enums/ride_enums.dart';
import 'package:yatrix/core/errors/app_exception.dart';
import 'package:yatrix/core/network/paginated.dart';
import 'package:yatrix/features/ride_requests/data/dto/ride_request_dto.dart';
import 'package:yatrix/features/rides/data/datasources/ride_remote_datasource.dart';
import 'package:yatrix/features/rides/data/dto/ride_dto.dart';
import 'package:yatrix/features/rides/data/dto/ride_participant_dto.dart';
import 'package:yatrix/features/rides/data/repositories/ride_repository_impl.dart';

Map<String, dynamic> rideJson({String id = 'r1', Map<String, dynamic>? myRequest}) => {
      'id': id,
      'title': 'Sunrise',
      'description': 'Easy loop',
      'date': '2030-01-02T03:04:05.000Z',
      'meetingPoint': 'Ratna Park',
      'rideType': 'hillClimb',
      'category': 'cycling',
      'difficulty': 'hard',
      'distanceKm': 42,
      'durationMinutes': 120,
      'organizerId': 'u1',
      'organizerName': 'Demo',
      'organizerAvatarUrl': '',
      'imageUrl': '',
      'participantCount': 3,
      'maxParticipants': 3,
      'isFull': true,
      'requirements': ['Helmet'],
      'participantAvatars': <String>[],
      'joinStatus': 'declined',
      'myRequest': myRequest,
      'createdAt': '2029-12-01T00:00:00.000Z',
    };

/// Records which endpoint the repository picked, and serves two pages.
class FakeRideRemote implements RideRemoteDataSource {
  final calls = <String>[];

  Paginated<RideDto> _page(String? cursor) => cursor == null
      ? Paginated(items: [RideDto.fromJson(rideJson(id: 'a'))], nextCursor: 'c1')
      : Paginated(items: [RideDto.fromJson(rideJson(id: 'b'))]);

  @override
  Future<Paginated<RideDto>> getMyRides(MyRidesScope scope, {DashboardCategory? category, String? cursor, int? limit}) async {
    calls.add('me:${scope.name}:$cursor');
    return _page(cursor);
  }

  @override
  Future<Paginated<RideDto>> getUserRides(String userId, {String? cursor, int? limit}) async {
    calls.add('user:$userId:$cursor');
    return _page(cursor);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('RideDto parses the API shape and round-trips', () {
    final dto = RideDto.fromJson(rideJson(myRequest: {
      'id': 'q1',
      'status': 'declined',
      'declineReason': 'Too fast',
      'requestedAt': '2029-12-02T00:00:00.000Z',
    }));
    expect(dto.rideType, RideType.hillClimb);
    expect(dto.category, DashboardCategory.cycling);
    expect(dto.distanceKm, 42.0);
    expect(dto.date.toUtc(), DateTime.utc(2030, 1, 2, 3, 4, 5));
    final ride = dto.toEntity();
    expect(ride.isFull, isTrue);
    expect(ride.joinStatus, RideJoinStatus.declined);
    expect(ride.myRequest?.declineReason, 'Too fast');
    expect(RideDto.fromJson(dto.toJson()).toJson(), dto.toJson());
  });

  test('unknown enum values fall back instead of crashing', () {
    final dto = RideDto.fromJson({...rideJson(), 'joinStatus': 'banned', 'rideType': 'unicycle'});
    expect(dto.joinStatus, RideJoinStatus.none);
    expect(dto.rideType, RideType.road);
  });

  test('RideInputDto only sends the fields that are set', () {
    final json = RideInputDto(title: 'New', date: DateTime.utc(2030), rideType: RideType.dayHike).toJson();
    expect(json, {'title': 'New', 'date': '2030-01-01T00:00:00.000Z', 'rideType': 'dayHike'});
  });

  test('RideRequestDto and RideParticipantDto parse', () {
    final request = RideRequestDto.fromJson({
      'id': 'q1',
      'rideId': 'r1',
      'rideTitle': 'Sunrise',
      'rideDate': '2030-01-02T03:04:05.000Z',
      'userId': 'u2',
      'userName': 'Aarav',
      'userAvatarUrl': '',
      'userBio': 'Hi',
      'message': null,
      'experienceLevel': 'advanced',
      'requestedAt': '2029-12-02T00:00:00.000Z',
      'status': 'approved',
      'declineReason': null,
      'decidedAt': '2029-12-03T00:00:00.000Z',
    }).toEntity();
    expect(request.status, RideRequestStatus.approved);
    expect(request.experienceLevel, ExperienceLevel.advanced);
    expect(request.decidedAt, isNotNull);

    final participant = RideParticipantDto.fromJson({
      'id': 'p1',
      'rideId': 'r1',
      'userId': 'u2',
      'name': 'Aarav',
      'avatarUrl': '',
      'joinedAt': '2029-12-03T00:00:00.000Z',
    });
    expect(RideParticipantDto.fromJson(participant.toJson()).userId, 'u2');
  });

  group('RideRepositoryImpl', () {
    late FakeRideRemote remote;
    late RideRepositoryImpl repository;

    setUp(() {
      remote = FakeRideRemote();
      repository = RideRepositoryImpl(remote, () => 'me');
    });

    test('uses /me/rides for the signed-in rider and follows every page', () async {
      final rides = await repository.getOrganizedRides('me');
      expect(rides.map((r) => r.id), ['a', 'b']);
      expect(remote.calls, ['me:organized:null', 'me:organized:c1']);
    });

    test('uses /users/:id/rides for other riders', () async {
      await repository.getOrganizedRides('other');
      expect(remote.calls.first, 'user:other:null');
    });

    test('joined and past rides are only available for the signed-in rider', () async {
      expect((await repository.getJoinedRides('me')).length, 2);
      expect((await repository.getPastRides('me')).length, 2);
      expect(remote.calls.where((c) => c.startsWith('me:joined')).length, 2);
      await expectLater(repository.getJoinedRides('other'), throwsA(isA<ForbiddenException>()));
    });
  });
}
