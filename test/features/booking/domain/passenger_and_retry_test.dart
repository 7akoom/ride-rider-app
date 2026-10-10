import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/ride.dart';
import 'package:rider_app/features/booking/domain/use_cases/check_passenger.dart';
import 'package:rider_app/features/booking/domain/use_cases/order_ride.dart';
import 'package:rider_app/features/booking/domain/use_cases/quote_ride.dart';
import 'package:rider_app/features/booking/domain/use_cases/retry_ride.dart';

import '../fakes.dart';

void main() {
  test('a passenger needs a name and a mobile number; both are tidied', () {
    final ok = checkPassenger('  Rania   Kamal ', '0750 448 9210') as PassengerOk;

    expect(ok.passenger.name, 'Rania Kamal');
    expect(ok.passenger.phone, '+9647504489210');

    final wrong = checkPassenger(' ', '123') as PassengerWrong;
    expect(wrong.problems, {PassengerProblem.nameMissing, PassengerProblem.phoneInvalid});

    final long = checkPassenger('a' * 81, '07504489210') as PassengerWrong;
    expect(long.problems, {PassengerProblem.nameTooLong});
  });

  test('only a search the platform gave up on means no captain', () {
    expect(rideOf(noCaptain: true).noCaptainFound, isTrue);
    expect(rideOf(status: RideStatus.cancelled).noCaptainFound, isFalse);
    expect(rideOf(status: RideStatus.accepted).hasCaptain, isTrue);
  });

  test('a ride becomes its draft again, addresses as names', () {
    final draft = draftOf(rideOf());

    expect(draft.pickup?.title, 'Gulan Street');
    expect(draft.destination?.title, 'Family Mall');
    expect(draft.isComplete, isTrue);
  });

  test('trying again asks the same ride type and payment at a new price', () async {
    final rides = FakeRides();
    final retry = RetryRide(quote: QuoteRide(rides), order: OrderRide(rides));

    final result = await retry(rideOf(noCaptain: true, vehicleClass: 'comfort', payment: PaymentMethod.wallet));

    expect(result, isA<Ok<Ride>>());
    expect(rides.orders.single.$1.vehicleClass, 'comfort');
    expect(rides.orders.single.$2, PaymentMethod.wallet);
  });

  test('a ride type no longer offered falls back to the cheapest', () async {
    final rides = FakeRides(quotes: [quoteOf('economy', 3000)]);

    await RetryRide(quote: QuoteRide(rides), order: OrderRide(rides))(rideOf(vehicleClass: 'comfort'));

    expect(rides.orders.single.$1.vehicleClass, 'economy');
  });
}
