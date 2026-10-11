import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/network/api_exception.dart';
import 'package:rider_app/features/booking/data/captain_api.dart';
import 'package:rider_app/features/booking/data/captain_repository_impl.dart';
import 'package:rider_app/features/booking/data/ride_json.dart';
import 'package:rider_app/features/booking/domain/entities/captain.dart';
import 'package:rider_app/features/booking/domain/entities/ride.dart';

class _FakeCaptainApi implements CaptainApi {
  JsonMap captainAnswer = {};
  JsonMap positionAnswer = {};
  Object? positionError;

  @override
  Future<JsonMap> captain(String tripId) async => captainAnswer;

  @override
  Future<JsonMap> position(String tripId) async =>
      positionError == null ? positionAnswer : throw positionError!;
}

void main() {
  test('the captain is read with their car; fields left out are empty', () async {
    final api = _FakeCaptainApi()
      ..captainAnswer = {
        'driver': {
          'displayName': 'Salem Suleiman',
          'ratingAverage': 4.86,
          'ratingCount': 1240,
          'photoUrl': 'https://photos.example/1',
          'vehicle': {'make': 'Toyota', 'model': 'Corolla', 'color': 'white', 'plateNumber': '22 A 25626'},
        },
      };

    final captain = ((await CaptainRepositoryImpl(api).captain('t1')) as Ok<Captain>).value;

    expect(captain.name, 'Salem Suleiman');
    expect(captain.rating, 4.86);
    expect(captain.car, 'Toyota Corolla · white');
    expect(captain.plate, '22 A 25626');

    api.captainAnswer = {
      'driver': {'displayName': 'New', 'ratingAverage': 0, 'vehicle': {'color': 'red'}},
    };
    final fresh = ((await CaptainRepositoryImpl(api).captain('t1')) as Ok<Captain>).value;

    expect(fresh.rating, isNull);
    expect(fresh.car, 'red');
    expect(fresh.photoUrl, isEmpty);
  });

  test('the position is read; a captain who has not reported is no position', () async {
    final api = _FakeCaptainApi()
      ..positionAnswer = {
        'location': {'latitude': 36.2, 'longitude': 44.01},
      };
    final repository = CaptainRepositoryImpl(api);

    expect(((await repository.position('t1')) as Ok<GeoPoint?>).value, const GeoPoint(36.2, 44.01));

    api.positionError = const ApiException(statusCode: 404, code: 5, message: 'not reported');
    expect(((await repository.position('t1')) as Ok<GeoPoint?>).value, isNull);

    api.positionError = const ApiException(statusCode: 503, code: 14, message: 'down');
    expect(await repository.position('t1'), isA<Err<GeoPoint?>>());
  });

  test('a trip says who it is for, when the captain arrived, who cancelled and the stops passed',
      () {
    final ride = RideJson.fromTrip({
      'id': 't1',
      'riderId': 'r1',
      'status': 'TRIP_STATUS_ACCEPTED',
      'arrivedAt': '2026-10-11T08:00:00Z',
      'cancelledBy': 'driver',
      'stops': [
        {'coordinates': {'latitude': 36.2, 'longitude': 44.0}, 'reachedAt': '2026-10-11T08:10:00Z'},
        {'coordinates': {'latitude': 36.21, 'longitude': 44.0}},
      ],
    });

    expect(ride.riderId, 'r1');
    expect(ride.stage, TripStage.arrived);
    expect(ride.cancelledByCaptain, isTrue);
    expect(ride.stops.map((stop) => stop.reached), [true, false]);
  });
}
