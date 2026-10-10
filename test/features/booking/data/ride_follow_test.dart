import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/network/api_exception.dart';
import 'package:rider_app/features/booking/data/rides_repository_impl.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/ride.dart';

import 'fake_rides_api.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({'rider_id': 'r1'}));

  test('a ride the platform gave up on is a ride with no captain', () async {
    final api = FakeRidesApi()
      ..followed = {
        'trip': {
          'id': 't1',
          'status': 'TRIP_STATUS_CANCELLED',
          'pickup': {'latitude': 36.19, 'longitude': 44.01},
          'dropoff': {'latitude': 36.23, 'longitude': 43.98},
          'dropoffAddress': 'Family Mall',
          'vehicleClass': 'comfort',
          'paymentMethod': 'wallet',
          'quotedFare': '3750.00',
          'cancelledBy': 'system',
          'cancellationReason': 'no drivers available',
          'stops': [
            {'coordinates': {'latitude': 36.2, 'longitude': 44.0}, 'address': 'Pharmacy'},
          ],
        },
      };

    final ride = ((await RidesRepositoryImpl(api).ride('t1')) as Ok<Ride>).value;

    expect(ride.noCaptainFound, isTrue);
    expect(ride.fare, 3750);
    expect(ride.payment, PaymentMethod.wallet);
    expect(ride.stops.single.address, 'Pharmacy');
    expect(ride.dropoffAddress, 'Family Mall');
  });

  test('no trip under way is no active ride, not a failure', () async {
    final api = FakeRidesApi()..activeError = const ApiException(statusCode: 404, code: 5, message: 'none');

    final result = await RidesRepositoryImpl(api).activeRide();

    expect((result as Ok<Ride?>).value, isNull);
  });

  test('cancelling says why, for staff', () async {
    final api = FakeRidesApi()
      ..followed = {
        'trip': {'id': 't1', 'status': 'TRIP_STATUS_CANCELLED', 'cancelledBy': 'rider'},
      };

    final ride = ((await RidesRepositoryImpl(api).cancel('t1')) as Ok<Ride>).value;

    expect(api.cancelReason, RidesRepositoryImpl.cancelReason);
    expect(ride.status, RideStatus.cancelled);
    expect(ride.noCaptainFound, isFalse);
  });
}
