import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/features/booking/booking_providers.dart';
import 'package:rider_app/features/booking/domain/entities/fare_quote.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/trip_draft.dart';
import 'package:rider_app/features/booking/presentation/choose_ride/choose_ride_controller.dart';
import 'package:rider_app/features/booking/presentation/choose_ride/choose_ride_state.dart';
import 'package:rider_app/features/offers/offers_providers.dart';

import '../fakes.dart';

final _draft = TripDraft(pickup: spotNamed('Gulan'), destination: spotNamed('Mall'));

/// A container with [rides], whose controller stays alive for the test.
Future<(ProviderContainer, ChooseRideController)> _open(FakeRides rides, {FakeOffers? offers}) async {
  final container = ProviderContainer(
    overrides: [
      ridesRepositoryProvider.overrideWithValue(rides),
      offersRepositoryProvider.overrideWithValue(offers ?? FakeOffers()),
    ],
  );
  addTearDown(container.dispose);
  container.listen(chooseRideControllerProvider(_draft), (_, __) {});
  await pumpEventQueue();

  return (container, container.read(chooseRideControllerProvider(_draft).notifier));
}

ChooseRideState _state(ProviderContainer c) => c.read(chooseRideControllerProvider(_draft));

void main() {
  group('a code kept on the home for the next ride', () {
    test('is tried on the first prices, and forgotten once a trip used it', () async {
      final rides = FakeRides();
      final offers = FakeOffers(kept: FakeRides.goodCode);
      final (container, controller) = await _open(rides, offers: offers);

      expect(rides.couponsTried.first, FakeRides.goodCode);
      expect(_state(container).coupon, CouponResult.applied);
      expect(offers.kept, FakeRides.goodCode);

      await controller.order();
      await pumpEventQueue();

      expect(offers.kept, isNull);
    });

    test('is forgotten when the rider removes it', () async {
      final offers = FakeOffers(kept: FakeRides.goodCode);
      final (_, controller) = await _open(FakeRides(), offers: offers);

      await controller.removeCoupon();
      await pumpEventQueue();

      expect(offers.kept, isNull);
    });

    test('is forgotten when no ride type will take it', () async {
      final offers = FakeOffers(kept: 'GONE26');
      final (container, _) = await _open(FakeRides(), offers: offers);
      await pumpEventQueue();

      expect(_state(container).coupon, CouponResult.notFound);
      expect(offers.kept, isNull);
    });

    test('a code typed here is never forgotten for the rider', () async {
      final offers = FakeOffers(kept: FakeRides.goodCode);
      final (_, controller) = await _open(FakeRides(), offers: offers);

      await controller.applyCoupon('other');
      await controller.removeCoupon();
      await pumpEventQueue();

      expect(offers.forgotten, 0);
      expect(offers.kept, FakeRides.goodCode);
    });
  });

  test('the cheapest ride is chosen first, and a choice survives new prices', () async {
    final (container, controller) = await _open(FakeRides());

    expect(_state(container).selectedClass, 'economy');

    controller.select('comfort');
    await controller.applyCoupon(FakeRides.goodCode);

    expect(_state(container).selectedClass, 'comfort');
    expect(_state(container).selected?.total, 3750 * 3 ~/ 4);
    expect(_state(container).coupon, CouponResult.applied);
  });

  test('removing the coupon asks for prices without it', () async {
    final rides = FakeRides();
    final (container, controller) = await _open(rides);

    await controller.applyCoupon('nope');
    expect(_state(container).coupon, CouponResult.notFound);

    await controller.removeCoupon();
    expect(rides.couponsTried.last, isNull);
    expect(_state(container).coupon, CouponResult.none);
  });

  test('ordering sends the chosen price and payment, and returns the ride', () async {
    final rides = FakeRides();
    final (container, controller) = await _open(rides);

    controller.choosePayment(PaymentMethod.wallet);
    final ride = await controller.order();

    expect(ride?.id, 'trip-1');
    expect(rides.orders.single.$1.vehicleClass, 'economy');
    expect(rides.orders.single.$2, PaymentMethod.wallet);
    expect(_state(container).ordering, isFalse);
  });

  test('a price that is gone brings new prices and says why', () async {
    final rides = FakeRides(orderFailure: const NotFoundFailure());
    final (container, controller) = await _open(rides);
    final before = rides.couponsTried.length;

    expect(await controller.order(), isNull);
    await pumpEventQueue();

    expect(_state(container).orderFailure, isA<NotFoundFailure>());
    expect(rides.couponsTried.length, before + 1);
  });

  test('prices that cannot load leave nothing to order', () async {
    final (container, controller) =
        await _open(FakeRides(quoteFailure: const InvalidInputFailure()));

    expect(_state(container).quoteFailure, isA<InvalidInputFailure>());
    expect(_state(container).canOrder, isFalse);
    expect(await controller.order(), isNull);
  });
}

