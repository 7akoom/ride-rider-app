import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/features/booking/domain/entities/fare_quote.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/trip_draft.dart';
import 'package:rider_app/features/booking/domain/use_cases/load_wallet_balance.dart';
import 'package:rider_app/features/booking/domain/use_cases/order_ride.dart';
import 'package:rider_app/features/booking/domain/use_cases/quote_ride.dart';

import '../fakes.dart';

final _draft = TripDraft(pickup: spotNamed('Gulan'), destination: spotNamed('Mall'));

void main() {
  test('a coupon is sent trimmed and in capitals; blank is no coupon', () async {
    final rides = FakeRides();

    await QuoteRide(rides).call(_draft, couponCode: '  bts26 ');
    await QuoteRide(rides).call(_draft, couponCode: '   ');

    expect(rides.couponsTried, ['BTS26', null]);
  });

  test('a draft without a destination has no prices', () async {
    final result = await QuoteRide(FakeRides()).call(TripDraft(pickup: spotNamed('Gulan')));

    expect((result as Err).failure, isA<InvalidInputFailure>());
  });

  test('an expired price is not sent: the rider gets new prices', () async {
    final rides = FakeRides();
    final expired = FareQuote(
      id: 'old',
      vehicleClass: 'economy',
      total: 3000,
      expiresAt: DateTime(2026),
    );

    final result = await OrderRide(rides, clock: () => DateTime(2026, 2))
        .call(draft: _draft, quote: expired, payment: PaymentMethod.cash);

    expect(rides.orders, isEmpty);
    expect(orderProblemOf((result as Err).failure), OrderProblem.pricesChanged);
  });

  test('refusals the rider can act on are told apart', () {
    expect(orderProblemOf(const NotFoundFailure()), OrderProblem.pricesChanged);
    expect(orderProblemOf(const PreconditionFailure()), OrderProblem.notNow);
    expect(orderProblemOf(const NetworkFailure()), isNull);
  });

  test('a rider with no wallet yet has a zero balance', () async {
    final result =
        await LoadWalletBalance(FakeRides(balance: const Err(NotFoundFailure()))).call();

    expect((result as Ok<int>).value, 0);
  });

  test('the earliest expiry and the surge come from all the prices', () {
    final soon = DateTime(2026, 1, 1, 10);
    final quotes = FareQuotes([
      FareQuote(id: 'a', vehicleClass: 'economy', total: 1, expiresAt: soon.add(const Duration(minutes: 5))),
      FareQuote(id: 'b', vehicleClass: 'comfort', total: 2, expiresAt: soon, surging: true),
    ]);

    expect(quotes.expiresAt, soon);
    expect(quotes.surging, isTrue);
    expect(quotes.ofClass('comfort')?.id, 'b');
  });
}
