import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/error/failure.dart';
import 'package:rider_app/core/error/result.dart';
import 'package:rider_app/core/location/geo_point.dart';
import 'package:rider_app/features/booking/data/rides_repository_impl.dart';
import 'package:rider_app/features/booking/data/trip_body.dart';
import 'package:rider_app/features/booking/domain/entities/fare_quote.dart';
import 'package:rider_app/features/booking/domain/entities/passenger.dart';
import 'package:rider_app/features/booking/domain/entities/payment_method.dart';
import 'package:rider_app/features/booking/domain/entities/ride.dart';
import 'package:rider_app/features/booking/domain/entities/spot.dart';
import 'package:rider_app/features/booking/domain/entities/trip_draft.dart';

import '../fakes.dart';
import 'fake_rides_api.dart';

const _draft = TripDraft(
  pickup: Spot(point: GeoPoint(36.19, 44.01), kind: SpotKind.currentLocation, title: 'Gulan'),
  stops: [Spot(point: GeoPoint(36.2, 44.02), kind: SpotKind.pinned)],
  destination: Spot(
    point: GeoPoint(36.21, 44.03),
    kind: SpotKind.mall,
    title: 'Family Mall',
    detail: '100m Street',
  ),
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({'rider_id': 'r1'}));

  test('prices are read with discount, surge and coupon; missing fields are zero',
      () async {
    final api = FakeRidesApi()
      ..quoted = {
        'quotes': [
          {
            'quoteId': 'q1',
            'vehicleClass': 'economy',
            'expiresAt': '2026-10-10T10:00:00Z',
            'driversAvailable': true,
            'pickupEtaMinutes': 4,
            'fare': {
              'total': '3000.00',
              'discountAmount': '1250',
              'surgeAmount': '500',
              'couponStatus': 'COUPON_STATUS_APPLIED',
            },
          },
          {
            'quoteId': 'q2',
            'vehicleClass': 'comfort',
            'expiresAt': '2026-10-10T10:00:00Z',
            'fare': {'total': '3750'},
          },
        ],
      };

    final result = await RidesRepositoryImpl(api).quote(_draft, couponCode: 'BTS26');
    final quotes = (result as Ok<FareQuotes>).value;

    expect(api.sent?['couponCode'], 'BTS26');
    expect(api.sent?['stops'], [
      {'latitude': 36.2, 'longitude': 44.02},
    ]);
    expect(quotes.surging, isTrue);
    expect(quotes.quotes.first.total, 3000);
    expect(quotes.quotes.first.beforeDiscount, 4250);
    expect(quotes.quotes.first.coupon, CouponResult.applied);
    expect(quotes.quotes.last.driversAvailable, isFalse);
    expect(quotes.quotes.last.pickupEtaMinutes, 0);
    expect(quotes.quotes.last.beforeDiscount, isNull);
  });

  test('a price without a total is a malformed answer, never shown', () async {
    final api = FakeRidesApi()
      ..quoted = {
        'quotes': [
          {'quoteId': 'q1', 'vehicleClass': 'economy', 'expiresAt': '2026-10-10T10:00:00Z'},
        ],
      };

    final result = await RidesRepositoryImpl(api).quote(_draft);

    expect((result as Err).failure, isA<UnexpectedFailure>());
  });

  test('the request carries the price, payment, addresses and stops', () async {
    final api = FakeRidesApi();

    final result = await RidesRepositoryImpl(api).request(
      draft: _draft,
      quote: quoteOf('comfort', 3750),
      payment: PaymentMethod.wallet,
      passenger: const Passenger(name: 'Rania', phone: '+9647504489210'),
    );

    expect((result as Ok<Ride>).value.id, 'trip-9');
    expect(api.sent?['passengerName'], 'Rania');
    expect(api.sent?['passengerPhone'], '+9647504489210');
    expect(api.sent?['quoteId'], 'q-comfort-3750');
    expect(api.sent?['vehicleClass'], 'comfort');
    expect(api.sent?['paymentMethod'], 'wallet');
    expect(api.sent?['pickupAddress'], 'Gulan');
    expect(api.sent?['dropoffAddress'], 'Family Mall, 100m Street');
    expect((api.sent?['stops'] as List).single['address'], '');
  });

  test('an address is cut at the backend limit', () {
    final long = Spot(point: const GeoPoint(0, 0), kind: SpotKind.other, title: 'a' * 400);

    expect(TripBody.addressOf(long).length, TripBody.maxAddressLength);
  });

  test('the wallet balance is read in whole units', () async {
    final api = FakeRidesApi()
      ..walletAnswer = {
        'wallet': {'balance': '12500.4', 'currencyCode': 'IQD'},
      };

    final result = await RidesRepositoryImpl(api).walletBalance();

    expect((result as Ok<int>).value, 12500);
  });
}
